import argparse
import getpass
import glob
import json
import pathlib
import re
import shutil
import subprocess
import sys
import zipfile

CWD = pathlib.Path(__file__).parent


def deploy(args):
    # terraform init
    # terraform plan ?
    # terraform apply
    ...


def setup_azure(args):
    azurecli_path = shutil.which("az")
    terraform_path = shutil.which("terraform")
    if not (azurecli_path and terraform_path):
        raise ValueError("You need to have both Terraform and Azure CLI installed.")

    result = subprocess.run(["az", "login"], capture_output=True, text=True)
    if result.returncode != 0:
        print("Error occurred when logging into Azure using the CLI:", result.stderr)
        sys.exit(result.returncode)

    env_file_path = CWD / ".env"
    env_file_path.touch()
    create_sp = False
    env_file = open(env_file_path, mode="rw")
    env_vars = re.findall(r"(\w+)\s?=\s?(\w+|\".+\")", env_file.read())

    if len(env_vars) == 0:
        create_sp = True
    else:
        sp_found = False
        for key, _ in env_vars:
            if key == "ARM_CLIENT_ID":
                sp_found = True
        create_sp = not sp_found

    if create_sp:
        azure_login_out = json.loads(result.stdout[result.stdout.index("[") :])
        if len(azure_login_out) > 1:
            for i, subscription in enumerate(azure_login_out):
                print(f"{i}: {subscription['name']}")
            subscription_idx = input(
                f"Choose a subscription to use (0-{len(azure_login_out) - 1}, default=0): "
            )
            if not subscription_idx:
                subscription_idx = "0"
            subscription_idx = int(subscription_idx)
            if subscription_idx < 0 or subscription_idx >= len(azure_login_out):
                raise ValueError(f"Invalid subscription number {subscription_idx}.")
        else:
            subscription_idx = 0
        subscription_id = azure_login_out[subscription_idx]["id"]
        result = subprocess.run(
            ["az", "account", "set", "--subscription", subscription_id]
        )
        if result.returncode != 0:
            print("Error occurred when setting up the Azure subscription")
            sys.exit(result.returncode)

        result = subprocess.run(
            [
                "az",
                "ad",
                "sp",
                "create-for-rbac",
                '--role="Owner"',
                f'--scopes="/subscriptions/{subscription_id}"',
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0 or not result.stdout:
            print(
                "Error occurred when creating an Azure Service principal:",
                result.stderr,
            )
            sys.exit(result.returncode)
        block_start_idx, block_end_idx = (
            result.stdout.index("{"),
            result.stdout.index("}"),
        )
        sp = json.loads(result.stdout[block_start_idx:block_end_idx])
        env_file.writelines(
            [
                "# TERRAFORM",
                f"export ARM_CLIENT_ID = {sp['appId']}",
                f"export ARM_CLIENT_SECRET = {sp['password']}",
                f"export ARM_TENANT_ID = {sp['tenant']}",
                f"export ARM_SUBSCRIPTION_ID = {subscription_id}",
            ]
        )

        print("Azure successfully set up!")
    else:
        print(
            (
                "Looks like Azure is already set up. "
                "Delete your .env file and run this command again "
                "if you want to start from scratch."
            )
        )

    env_file.close()


def _from_args_or_prompt(args, attr: str, label: str, password: bool = False):
    var = ""
    if not (var := getattr(args, attr)):
        if not password:
            var = input(f"Enter your {label}: ")
        else:
            var = getpass.getpass(f"Enter your {label}: ")
        if not var:
            raise ValueError(f"You need to provide your {label}")
    return var


def generate_secrets(args):
    # 1) Get BO2 files
    local_bo2_zip = CWD / ".secrets" / "t6.zip"
    if not local_bo2_zip.exists() or args.update:
        if not args.steamcmd_path:
            steamcmd_path = shutil.which("steamcmd")
            if not steamcmd_path:
                raise ValueError(
                    "'steamcmd' not found. Please provide its path with --steamcmd-path."
                )
            else:
                steamcmd_path = pathlib.Path(steamcmd_path)
        else:
            steamcmd_path = args.steamcmd_path

        steamcmd_bo2 = steamcmd_path.parent / "bo2"
        steamcmd_bo2_files = [
            file for file in steamcmd_bo2.iterdir() if "steamapps" not in file.name
        ]
        if not steamcmd_bo2.exists() or not steamcmd_bo2_files or args.update:
            steam_username = _from_args_or_prompt(
                args, "steam_username", "Steam username"
            )
            steam_password = _from_args_or_prompt(
                args, "steam_password", "Steam password", password=True
            )

            bo2_install_command = [
                steamcmd_path,
                "@ShutdownOnFailedCommand",
                "1",
                "+@sSteamCmdForcePlatformType",
                "windows",
                "+@NoPromptForPassword",
                "1",
                "+force_install_dir",
                "./bo2",
                "+login",
                steam_username,
                steam_password,
                "+app_update",
                "212910",
                "validate",
                "+quit",
            ]

            process = subprocess.run(bo2_install_command)
            if process.returncode != 0:
                print(
                    "An error occured when running steamcmd and downloading the BO2 files."
                )
                sys.exit(process.returncode)

        local_bo2 = CWD / ".secrets" / "bo2"
        shutil.copytree(steamcmd_bo2, local_bo2, dirs_exist_ok=True)
        for folder in ["video", "redist", "steamapps", "Soundtrack", "sound"]:
            if (local_bo2 / folder).exists():
                shutil.rmtree(local_bo2 / folder)
        for file in ["installscript.vdf", "t6zm.exe", "steam_api.dll"]:
            (local_bo2 / file).unlink(missing_ok=True)
        for file in glob.glob(f"{local_bo2}/**/*.ipak", recursive=True):
            pathlib.Path(file).unlink(missing_ok=True)
        bo2_dir_size = sum(
            file.stat().st_size for file in local_bo2.rglob("*") if file.is_file()
        ) / (1024**2)
        print("Trimmed BO2 directory size (MB): ", bo2_dir_size)

        # Zip it up
        with zipfile.ZipFile(
            CWD / ".secrets" / "t6.zip", "w", zipfile.ZIP_DEFLATED
        ) as zipf:
            for root, _, files in local_bo2.walk():
                for file in files:
                    file_path = pathlib.Path(root) / file
                    relative_path = file_path.relative_to(local_bo2)
                    zipf.write(file_path, relative_path)
        print("Zipped t6 server data to .secrets/t6.zip")
        shutil.rmtree(local_bo2)

    # # 2) Generate the SSH key files
    # ssh_key_path = CWD / ".secrets" / "id_ed5519"
    #
    # if not ssh_key_path.exists():
    #     ssh_key_password = _from_args_or_prompt(
    #         args, "ssh_key_password", "SSH key password", password=True
    #     )
    #
    #     ssh_keygen_command = [
    #         "ssh-keygen",
    #         "-t",
    #         "ed25519",
    #         "-f",
    #         str(ssh_key_path),
    #         "-N",
    #         ssh_key_password,
    #         "-q",
    #     ]
    #
    #     process = subprocess.run(ssh_keygen_command)
    #     if process.returncode != 0:
    #         print(
    #             "Failed to generate SSH key. Error occurred when running 'ssh-keygen'."
    #         )
    #         sys.exit(process.returncode)


def main(args):
    if args.subcommand == "gen-secrets":
        generate_secrets(args)
    elif args.subcommand == "setup-azure":
        setup_azure(args)
    else:
        raise ValueError(f"Invalid subcommand: {args.subcomand}")


def parse_args():
    parser = argparse.ArgumentParser(prog="t6")

    sub_parsers = parser.add_subparsers(dest="subcommand")

    generate_secrets = sub_parsers.add_parser(
        "gen-secrets",
        help=(
            "Generates secrets. Needed to be done once to set up the server."
            "Enter your Steam username, password and steamguard code if prompted."
            "The utility will download the BO2 server files (if not already on your device), "
            "and trim them down to just the required 500mb files that will be "
            "uploaded to the server later. \n"
            "The utility caches login information for your Steam account to use "
            "for downloading the BO2 server files. "
            "It also generates an SSH key to use "
            "for the admin account of the VM."
        ),
    )
    generate_secrets.add_argument(
        "--update", type=bool, default=False, help="Update the BO2 server files."
    )
    generate_secrets.add_argument(
        "--steamcmd-path", type=pathlib.Path, default=None, help="The path to steamcmd."
    )
    generate_secrets.add_argument(
        "--steam-username", type=str, default=None, help="Your Steam username."
    )
    generate_secrets.add_argument(
        "--steam-password", type=str, default=None, help="Your Steam password."
    )
    generate_secrets.add_argument(
        "--ssh-key-password",
        type=str,
        default=None,
        help="The password for the SSH key.",
    )

    _setup_azure = sub_parsers.add_parser(
        "setup-azure",
        help=(
            "Sets up Azure for use with Terraform. "
            "Generates the needed Service Principal and stores all the "
            "necessary environment variables in a .env file."
        ),
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    main(args)

import argparse
import shutil
import subprocess
import sys
import pathlib
import getpass
import glob


CWD = pathlib.Path(__file__).parent


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
    local_bo2 = CWD / ".secrets" / "bo2"
    if not local_bo2 or args.update:
        steam_username = _from_args_or_prompt(args, "steam_username", "Steam username")
        steam_password = _from_args_or_prompt(
            args, "steam_password", "Steam password", password=True
        )
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
            print("An error occured when running steamcmd and downloading the BO2 files.")
            sys.exit(process.returncode)

        shutil.copy(steamcmd_path.parent / "bo2", CWD / ".secrets" / "bo2")
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

    # 2) Generate the SSH key files
    ssh_key_path = CWD / ".secrets" / "id_ed5519"

    if not ssh_key_path.exists():
        ssh_key_password = _from_args_or_prompt(
            args, "ssh_key_password", "SSH key password", password=True
        )

        ssh_keygen_command = [
            "ssh-keygen",
            "-t",
            "ed25519",
            "-f",
            str(CWD / ".secrets" / "id_ed5519"),
            "-N",
            ssh_key_password,
            "-q",
        ]

        process = subprocess.run(ssh_keygen_command)
        if process.returncode != 0:
            print("Failed to generate SSH key. Error occurred when running 'ssh-keygen'.")
            sys.exit(process.returncode)


def main(args):
    if args.subcommand == "gen-secrets":
        generate_secrets(args)
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

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    main(args)

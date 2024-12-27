# t6server

Scripts and infrastructure-as-code to automate the deployment of a Plutonium server for Call of Duty: Black Ops 2 Zombies.

The code can deploy a Windows Server 2022 to Azure and set it up with Plutonium.


## Requirements
- [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD)
- [Python](https://www.python.org/downloads/) >= 3.10
- [Terraform](https://www.terraform.io)
- a Microsoft account and an Azure subscription

## Setup

> [!NOTE]
> Unlike other T6 server automation solutions, we do not provide existing BO2 installation files. Instead, you will need to install SteamCMD on your local machine that you will deploy VMs from. Then you can use the `cli.py` utility to download the required files with the `gen-secrets` command. This will ask you to provide login credentials for a Steam account that has a license for Black Ops 2. These credentials will not be stored anywhere. On some platforms like Linux, SteamCMD does cache a user session token in `$(which steamcmd)/config/config.vdf`, but that's unrelated to this application.

0. Ensure you've got all the requirements set up.
1. Run `python3 cli.py gen-secrets`. If you installed SteamCMD manually and it's not in your PATH, then you should provide its filepath with the `--steamcmd-path` argument.


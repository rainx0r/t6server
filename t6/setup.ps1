param(
    [Parameter(Mandatory=$true)]
    [string]
    $serverName,
    [Parameter(Mandatory=$true)]
    [string]
    $serverKey,
    [Parameter(Mandatory=$true)]
    [string]
    $serverPassword,
    [Parameter(Mandatory=$true)]
    [string]
    $serverRconPassword
)

# Download game files from storage
New-Item -ItemType Directory -Force -Path "C:\server"
Copy-Item -Path "start.bat" -Destination "C:\server\start.bat"
Copy-Item -Path "server.cfg" -Destination "C:\server\server.cfg"
Expand-Archive -Path "t6.zip" -DestinationPath "C:\server\t6"
cd C:\server

# Install choco and dependencies
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
C:\ProgramData\Chocolatey\choco.exe install vcredist140 directx -y

# Update plutonium
Invoke-WebRequest -Uri 'https://github.com/mxve/plutonium-updater.rs/releases/latest/download/plutonium-updater-x86_64-pc-windows-msvc.zip' -OutFile 'plutonium-updater.zip'
Expand-Archive -Path 'plutonium-updater.zip' -DestinationPath '.\t6' -Force
Remove-Item "plutonium-updater.zip"
cd t6
.\plutonium-updater.exe -d .

# Install configs
Invoke-WebRequest -Uri 'https://github.com/xerxes-at/T6ServerConfigs/archive/master.zip' -OutFile 'configs.zip'
Expand-Archive -Path 'configs.zip' -DestinationPath '.\configs' -Force
Remove-Item "configs.zip"
Copy-Item -Path "configs\T6ServerConfigs-master\!updatePluto.bat" -Destination "!updatePluto.bat"
Copy-Item -Path "configs\T6ServerConfigs-master\localappdata\Plutonium\*" -Destination "." -Recurse -Force
Remove-Item -Path "configs" -Recurse -Force

# Firewall
New-NetFirewallRule -DisplayName "T6 Server" -Direction Inbound -Action Allow -Program ".\bin\plutonium-bootstrapper-win32.exe" -Enabled True
New-NetFirewallRule -DisplayName "Open Port 4976" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 4976
New-NetFirewallRule -DisplayName "ICMP Allow incoming V4 echo request" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow

# Start server
cd C:\server
cmd /c start.bat "$serverName" "$serverKey" "$serverPassword" "$serverRconPassword"

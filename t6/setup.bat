:: Install chocolatey & Visual C++ Runtime & DirectX & ntop & vim
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
powershell -Command "C:\ProgramData\Chocolatey\choco.exe install vcredist140 directx ntop vim -y"

REM :: Install steamcmd
REM powershell -Command "Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile 'steamcmd.zip'"
REM powershell -Command "Expand-Archive -Path 'steamcmd.zip' -Force"
REM del "steamcmd.zip"
REM copy "steamcmd\steamcmd.exe" "%cd%\"
REM rd /s /q "steamcmd"
REM
REM :: Install BO2
REM steamcmd +force_install_dir "./bo2" +login %STEAM_USERNAME% +app_update 212910 validate +quit
REM for %%d in (video redist steamapps Soundtrack sound) do rd /s /q ".\bo2\%%d"
REM del ".\bo2\installscript.vdf" ".\bo2\t6zm.exe" ".\bo2\steam_api.dll"
REM for /r %%i in (*.ipak) do del "%%i"

:: Set up Plutonium Updater
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/mxve/plutonium-updater.rs/releases/latest/download/plutonium-updater-x86_64-pc-windows-msvc.zip' -OutFile 'plutonium-updater.zip'"
powershell -Command "Expand-Archive -Path 'plutonium-updater.zip' -DestinationPath '.\bo2' -Force"
del "plutonium-updater.zip"
cd ".\bo2"
.\plutonium-updater.exe -d .

:: Download configs
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/xerxes-at/T6ServerConfigs/archive/master.zip' -OutFile 'configs.zip'"
powershell -Command "Expand-Archive -Path 'configs.zip' -DestinationPath '.\configs' -Force"
del "configs.zip"
:: TODO: decide how to move !start_zm_server.bat
copy "configs\T6ServerConfigs-master\!updatePluto.bat" "!updatePluto.bat"
robocopy "configs\T6ServerConfigs-master\localappdata\Plutonium" . /E /COPYALL /Z /MT
rd /s /q "configs"

:: Configure firewall
netsh advfirewall firewall add rule name="T6 Server" dir=in action=allow program=".\bo2\bin\plutonium-bootstrapper-win32.exe" enable=yes
netsh advfirewall firewall add rule name= "Open Port 4976" dir=in action=allow protocol=UDP localport=4976
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow


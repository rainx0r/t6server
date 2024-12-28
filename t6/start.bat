@echo off
set cfg=server.cfg
set port=4976
set mod=""
set SERVER_NAME=%1
set SERVER_KEY=%2
set SERVER_PASSWORD=%3
set RCON_PASSWORD=%4

move /y %cfg% C:\server\t6\storage\t6\

cd C:\server\t6

powershell -Command "(gc storage\t6\%cfg%) -replace 'SERVER_PASSWORD_HERE', '%SERVER_PASSWORD%' | Out-File -encoding ASCII storage\t6\%cfg%"
powershell -Command "(gc storage\t6\%cfg%) -replace 'RCON_PASSWORD_HERE', '%RCON_PASSWORD%' | Out-File -encoding ASCII storage\t6\%cfg%"

title PlutoniumT6 - %SERVER_NAME% - Server restarter
echo Server "%SERVER_NAME%" will load %cfg% and listen on port %port% UDP!
echo (%date%)  -  (%time%) %SERVER_NAME% server start.

start /abovenormal bin\plutonium-bootstrapper-win32.exe t6zm "%cd%" -dedicated +set key %SERVER_KEY% +set fs_game %mod% +set net_port %port% +exec %cfg% +map_rotate

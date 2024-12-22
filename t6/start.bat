@echo off
set cfg=dedicated_zm.cfg
set port=4976
set mod=""

title PlutoniumT6 - %SERVER_NAME% - Server restarter
echo Server "%SERVER_NAME%" will load %cfg% and listen on port %port% UDP!
echo (%date%)  -  (%time%) %SERVER_NAME% server start.

:server
start /wait /abovenormal bin\plutonium-bootstrapper-win32.exe t6zm "%cd%" -dedicated +set key %SERVER_KEY% +set fs_game %mod% +set net_port %port% +exec %cfg% +map_rotate
echo (%date%)  -  (%time%) WARNING: %SERVER_NAME% server closed or dropped... server restarts.
goto server

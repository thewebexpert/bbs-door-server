@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\dredd
if exist c:\nodes\node%NODE%\door.sys copy c:\nodes\node%NODE%\door.sys c:\doors\dredd\door.sys > nul
if exist c:\nodes\node%NODE%\DOOR.SYS copy c:\nodes\node%NODE%\DOOR.SYS c:\doors\dredd\DOOR.SYS > nul
dredd c:\nodes\node%NODE%\door.sys
exit

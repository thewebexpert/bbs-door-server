@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\doormud
if exist c:\nodes\node%NODE%\door.sys copy c:\nodes\node%NODE%\door.sys c:\doors\doormud\door.sys > nul
if exist c:\nodes\node%NODE%\DOOR.SYS copy c:\nodes\node%NODE%\DOOR.SYS c:\doors\doormud\DOOR.SYS > nul
if exist c:\nodes\node%NODE%\dorinfo%NODE%.def copy c:\nodes\node%NODE%\dorinfo%NODE%.def c:\doors\doormud\dorinfo%NODE%.def > nul
if exist c:\nodes\node%NODE%\dorinfo1.def copy c:\nodes\node%NODE%\dorinfo1.def c:\doors\doormud\dorinfo1.def > nul
dmud.exe -n %NODE% -d c:\nodes\node%NODE%
exit

@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\tw2002
if exist c:\nodes\node%NODE%\dorinfo%NODE%.def copy c:\nodes\node%NODE%\dorinfo%NODE%.def c:\doors\tw2002\dorinfo%NODE%.def > nul
if exist c:\nodes\node%NODE%\dorinfo1.def copy c:\nodes\node%NODE%\dorinfo1.def c:\doors\tw2002\dorinfo1.def > nul
if exist c:\nodes\node%NODE%\DORINFO%NODE%.DEF copy c:\nodes\node%NODE%\DORINFO%NODE%.DEF c:\doors\tw2002\DORINFO%NODE%.DEF > nul
if exist c:\nodes\node%NODE%\DORINFO1.DEF copy c:\nodes\node%NODE%\DORINFO1.DEF c:\doors\tw2002\DORINFO1.DEF > nul
if exist c:\nodes\node%NODE%\DOOR.SYS copy c:\nodes\node%NODE%\DOOR.SYS c:\doors\tw2002\DOOR.SYS > nul
if exist c:\nodes\node%NODE%\door.sys copy c:\nodes\node%NODE%\door.sys c:\doors\tw2002\door.sys > nul
tw2002.exe TWNODE=%NODE% SHARE
exit

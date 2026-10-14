@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\fulllord
if exist c:\nodes\node%NODE%\dorinfo%NODE%.def copy c:\nodes\node%NODE%\dorinfo%NODE%.def c:\doors\fulllord\dorinfo%NODE%.def > nul
if exist c:\nodes\node%NODE%\dorinfo1.def copy c:\nodes\node%NODE%\dorinfo1.def c:\doors\fulllord\dorinfo1.def > nul
if exist c:\nodes\node%NODE%\DORINFO%NODE%.DEF copy c:\nodes\node%NODE%\DORINFO%NODE%.DEF c:\doors\fulllord\DORINFO%NODE%.DEF > nul
if exist c:\nodes\node%NODE%\DORINFO1.DEF copy c:\nodes\node%NODE%\DORINFO1.DEF c:\doors\fulllord\DORINFO1.DEF > nul
if exist c:\nodes\node%NODE%\door.sys copy c:\nodes\node%NODE%\door.sys c:\doors\fulllord\door.sys > nul
if exist c:\nodes\node%NODE%\DOOR.SYS copy c:\nodes\node%NODE%\DOOR.SYS c:\doors\fulllord\DOOR.SYS > nul
call start.bat %NODE%

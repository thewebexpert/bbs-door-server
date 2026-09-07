@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\lord
if exist c:\nodes\node%NODE%\dorinfo%NODE%.def copy c:\nodes\node%NODE%\dorinfo%NODE%.def c:\doors\lord\dorinfo%NODE%.def > nul
if exist c:\nodes\node%NODE%\dorinfo1.def copy c:\nodes\node%NODE%\dorinfo1.def c:\doors\lord\dorinfo1.def > nul
if exist c:\nodes\node%NODE%\DORINFO%NODE%.DEF copy c:\nodes\node%NODE%\DORINFO%NODE%.DEF c:\doors\lord\DORINFO%NODE%.DEF > nul
if exist c:\nodes\node%NODE%\DORINFO1.DEF copy c:\nodes\node%NODE%\DORINFO1.DEF c:\doors\lord\DORINFO1.DEF > nul
call start.bat %NODE%
exit

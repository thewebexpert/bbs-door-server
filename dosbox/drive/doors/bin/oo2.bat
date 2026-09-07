@echo off
c:
if "%NODE%"=="" set NODE=1
if not "%1"=="" set NODE=%1
bnu
bnu /c /l0:38400,8n1 /w0- /h0-
cd \doors\oo2
if exist BBSINFO.OO del BBSINFO.OO
if exist bbsinfo.oo del bbsinfo.oo
if exist oonode.dat del oonode.dat
if exist OONODE.DAT del OONODE.DAT
OOINFO.EXE 2 c:\nodes\node%NODE%\ %NODE%
OOII.EXE
if exist oonode.dat del oonode.dat
if exist OONODE.DAT del OONODE.DAT
exit

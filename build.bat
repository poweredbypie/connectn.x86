@echo off

set build="build"
if not exist %build% (
    echo Creating directory %build%
    mkdir %build%
)

for %%i in ("src\*.asm") do call :compile %%i
rem To be honest, I have no idea how to configure MASM to compile in another directory.
rem So I'm just moving it manually because I can't be bothered.
for %%i in ("*.obj") do move %%i %build%

link "%build%\*.obj" /entry:start /subsystem:console /out:"%build%\connectn.exe"
exit /b 1

:compile
echo "%~1"
ml /c %~1 /Fo:%~1.obj
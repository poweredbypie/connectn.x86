@echo off
cd build
call :compile main
call :compile cmdline
call :compile io
call :compile str
link *.obj /entry:start /subsystem:console /out:connectn.exe
cd ..
exit /b 1

:compile
ml /c ..\%~1.asm /Fo:%~1.obj
@echo off

if "%1" == "test" goto test
if "%1" == "clean" goto clean

:build
cl clc.c evaluator.c
exit /b

:test
if not exist clc.exe (call :build)
call tests-double.bat
exit /b

:clean
del *.obj clc.exe
exit /b
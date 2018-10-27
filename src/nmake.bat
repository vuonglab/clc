@echo off

if "%1" == "test" goto test
if "%1" == "clean" goto clean

:build
cl /O1 /MD clc.c evaluator.c
exit /b

:test
if not exist clc.exe (call :build)
call tests-double.bat
exit /b

:clean
if exist *.obj (del *.obj)
if exist clc.exe (del clc.exe)
exit /b
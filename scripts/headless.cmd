@echo off
setlocal EnableDelayedExpansion
if "%GODOT%"=="" set "GODOT=godot"
rem Doi duong dan tuong doi cua --scenario/--inputs/--out thanh tuyet doi (theo %CD%), nhu headless.sh.
set "HERE=%~dp0"
set "ARGS="
set "PREV="
:loop
if "%~1"=="" goto run
set "A=%~1"
set "OUT=!A!"
if /I "!PREV!"=="--scenario" call :abs
if /I "!PREV!"=="--inputs" call :abs
if /I "!PREV!"=="--out" call :abs
set "ARGS=!ARGS! "!OUT!""
set "PREV=%~1"
shift
goto loop
:abs
if "!A:~1,1!"==":" exit /b
if "!A:~0,1!"=="\" exit /b
if "!A:~0,1!"=="/" exit /b
set "OUT=%CD%\!A!"
exit /b
:run
"%GODOT%" --headless --path "!HERE!..\godot" --script res://src/adapters/headless/headless_runner.gd -- !ARGS!
exit /b %ERRORLEVEL%

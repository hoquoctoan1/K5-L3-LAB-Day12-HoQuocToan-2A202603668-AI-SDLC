@echo off
if "%GODOT%"=="" set "GODOT=godot"
"%GODOT%" --headless --path "%~dp0..\godot" --script res://src/adapters/headless/headless_runner.gd -- %*
exit /b %ERRORLEVEL%

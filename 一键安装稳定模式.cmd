@echo off
set "SCRIPT_DIR=%~dp0"
start "" pwsh.exe -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Start-StableMode.ps1"
exit /b 0

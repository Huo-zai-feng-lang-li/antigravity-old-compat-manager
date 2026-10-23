@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

set "PWSH_EXE="
if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" set "PWSH_EXE=%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe"
if not defined PWSH_EXE if exist "C:\Program Files\PowerShell\7\pwsh.exe" set "PWSH_EXE=C:\Program Files\PowerShell\7\pwsh.exe"
if not defined PWSH_EXE (
    where pwsh.exe >nul 2>nul
    if not errorlevel 1 set "PWSH_EXE=pwsh.exe"
)
if not defined PWSH_EXE set "PWSH_EXE=powershell.exe"

start "" "%PWSH_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Start-StableMode.ps1"
exit /b 0

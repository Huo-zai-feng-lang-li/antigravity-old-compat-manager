Option Explicit

Dim shell, fileSystem, scriptDirectory, powerShellPath, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
powerShellPath = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe")
If Not fileSystem.FileExists(powerShellPath) Then powerShellPath = "pwsh.exe"

command = """" & powerShellPath & """ -NoLogo -NoProfile -ExecutionPolicy Bypass -File """ & scriptDirectory & "\StableBootstrap.ps1"""
shell.Run command, 0, False

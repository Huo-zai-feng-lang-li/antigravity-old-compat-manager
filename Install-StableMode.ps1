[CmdletBinding()]
param(
    [string]$InstallRoot,
    [ValidateSet('Stable', 'Gemini37')]
    [string]$Mode = 'Stable',
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Windows.Forms
Import-Module (Join-Path $PSScriptRoot 'scripts\StableMode.Core.psm1') -Force

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Find-AntigravityInstallRoots | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    [Windows.Forms.MessageBox]::Show('未找到 Antigravity.exe。', '稳定模式安装失败', 'OK', 'Error') | Out-Null
    exit 1
}

if ($CheckOnly) {
    Get-CompatibilityInstallStatus -InstallRoot $InstallRoot -Mode $Mode | ConvertTo-Json -Depth 10
    exit 0
}

try {
    $result = Set-CompatibilityMode `
        -InstallRoot $InstallRoot `
        -BackupRoot (Join-Path $PSScriptRoot 'backups') `
        -Mode $Mode `
        -ClearModelCache `
        -AllowAdaptive
    $message = @"
$Mode 模式已一次性安装完成。

现在可以关闭本工具，以后直接打开：
$InstallRoot\Antigravity.exe

除非 IDE 文件被更新或覆盖，否则无需再次运行。
"@
    [Windows.Forms.MessageBox]::Show($message, '安装成功', 'OK', 'Information') | Out-Null
    exit 0
}
catch {
    [Windows.Forms.MessageBox]::Show($_.Exception.Message, '稳定模式安装失败', 'OK', 'Error') | Out-Null
    exit 1
}

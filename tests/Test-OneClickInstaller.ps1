$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path $PSScriptRoot -Parent
$installer = Join-Path $root 'Install-StableMode.ps1'
$gui = Join-Path $root 'Antigravity稳定模式.ps1'
$module = Join-Path $root 'scripts\StableMode.Core.psm1'
$launcher = Join-Path $root '一键安装稳定模式.cmd'

$tokens = $null
$errors = $null
[Management.Automation.Language.Parser]::ParseFile($installer, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -ne 0) { throw "安装器语法错误：$errors" }
$tokens = $null
$errors = $null
[Management.Automation.Language.Parser]::ParseFile($gui, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -ne 0) { throw "可视管理器语法错误：$errors" }

$installerSource = [IO.File]::ReadAllText($installer)
$guiSource = [IO.File]::ReadAllText($gui)
if (-not $installerSource.Contains('-AllowAdaptive')) { throw '安装器未启用自适应档案。' }
foreach ($required in @(
    "[ValidateSet('Stable', 'Gemini37')]",
    'Get-CompatibilityInstallStatus',
    'Set-CompatibilityMode'
)) {
    if (-not $installerSource.Contains($required)) { throw "安装器缺少双模式契约：$required" }
}
foreach ($required in @(
    "AutoSize = `$true; Text = 'Gemini 3.7 兼容模式（保留 Claude）'",
    '稳定模式（仅 Claude）',
    'Get-SelectedCompatibilityMode',
    'Invoke-ApplySelectedMode',
    'StableBootstrap.ps1',
    '-Mode',
    '-StopRunningProcesses',
    'Add_CheckedChanged',
    '检测模型目录',
    'CdpModelCatalog.mjs',
    'OfficialModelCatalog.mjs',
    '官方公开推理模型',
    '旧版 IDE 当前可见模型',
    'Gemini 3.7 已通过兼容名单放行'
)) {
    if (-not $guiSource.Contains($required)) { throw "可视管理器缺少双模式入口：$required" }
}
if ($guiSource.Contains('Set-StableMode')) { throw '可视管理器不得绕过 Bootstrap 直接修改 IDE。' }

$bytes = [IO.File]::ReadAllBytes($launcher)
if ($bytes | Where-Object { $_ -gt 127 }) { throw '一键入口内容必须为纯 ASCII。' }
$text = [Text.Encoding]::ASCII.GetString($bytes)
if ($text -notmatch '-WindowStyle Hidden') { throw '安装 PowerShell 必须隐藏。' }
if ($text -notmatch 'Start-StableMode\.ps1') { throw '一键入口未指向可视管理器。' }

Import-Module $module -Force
$detected = @(Find-AntigravityInstallRoots)
if ('D:\Antigravity' -notin $detected) { throw '自动检测未发现已安装的 D:\Antigravity。' }

$output = & pwsh -NoProfile -File $installer -InstallRoot 'D:\Antigravity' -Mode Stable -CheckOnly
if ($LASTEXITCODE -ne 0) { throw '安装器只读检查失败。' }
$status = $output | ConvertFrom-Json
if ($status.Root -ne 'D:\Antigravity') { throw '安装器未识别实际旧版目录。' }
if ($null -eq $status.PSObject.Properties['Passed']) { throw '安装器只读检查未返回稳定状态。' }
if ($status.Mode -ne 'Stable') { throw '安装器只读检查未返回 Stable 模式。' }
if (-not $status.Passed -and [string]::IsNullOrWhiteSpace($status.Message)) { throw '安装器发现待修复状态时未返回原因。' }

Write-Output 'PASS: one-click installer syntax, hidden launcher, and truthful read-only discovery'

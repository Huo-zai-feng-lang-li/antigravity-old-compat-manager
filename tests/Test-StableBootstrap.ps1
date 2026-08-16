$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path $PSScriptRoot -Parent
$bootstrap = Join-Path $root 'StableBootstrap.ps1'

$tokens = $null
$errors = $null
[Management.Automation.Language.Parser]::ParseFile($bootstrap, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -ne 0) { throw "自愈启动器语法错误：$errors" }
$bootstrapSource = [IO.File]::ReadAllText($bootstrap)
foreach ($required in @(
    "[ValidateSet('Stable', 'Gemini37')]",
    'selectedMode',
    'lastSuccessfulMode',
    'Set-CompatibilityMode',
    "currentSchemaVersion = 8",
    "currentPatchVersion = 'compatibility-v13-gemini37-real-route-gemini36'",
    'Find-AgentProSourcePath',
    'TargetAgentProCompatSha256',
    'StopRunningProcesses',
    'Find-TargetProfile $pair $profiles $selectedMode',
    '--remote-debugging-port=9000',
    '-ArgumentList $launchArguments'
)) {
    if (-not $bootstrapSource.Contains($required)) { throw "Bootstrap 缺少双模式契约：$required" }
}

$shortcutPath = Join-Path ([IO.Path]::GetTempPath()) ('AntigravityStable-' + [guid]::NewGuid().ToString('N') + '.lnk')
try {
    $output = & pwsh -NoProfile -File $bootstrap -InstallRoot 'D:\Antigravity' -Mode Stable -CheckOnly -NoLaunch -InstallShortcut -ShortcutPath $shortcutPath
    if ($LASTEXITCODE -ne 0) { throw "自愈启动器只读检查失败：$output" }
    $result = $output | ConvertFrom-Json
    if ($result.Root -ne 'D:\Antigravity') { throw '自愈启动器目录解析错误。' }
    if ([string]::IsNullOrWhiteSpace($result.MainSha256)) { throw '自愈启动器未返回 main.js 哈希。' }
    if ([string]::IsNullOrWhiteSpace($result.WorkbenchSha256)) { throw '自愈启动器未返回 workbench 哈希。' }
    if ([string]::IsNullOrWhiteSpace($result.ExtensionSha256)) { throw '自愈启动器未返回 extension.js 哈希。' }
    if ($result.SelectedMode -ne 'Stable') { throw '自愈启动器未返回显式 Stable 模式。' }
    if (-not (Test-Path -LiteralPath $shortcutPath)) { throw '未创建稳定版快捷方式。' }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $expectedTarget = Join-Path $env:SystemRoot 'System32\wscript.exe'
    if ($shortcut.TargetPath -ne $expectedTarget) { throw "快捷方式未使用无窗口宿主：$($shortcut.TargetPath)" }
    if ($shortcut.Arguments -notmatch 'Launch-StableHidden\.vbs') { throw '快捷方式未指向无窗口启动器。' }
    $vbs = Join-Path $root 'Launch-StableHidden.vbs'
    if (-not (Test-Path -LiteralPath $vbs)) { throw '缺少无窗口启动器。' }
    $vbsSource = [IO.File]::ReadAllText($vbs)
    if ($vbsSource -notmatch '\.Run command, 0, False') { throw '无窗口启动器没有使用隐藏异步运行。' }
}
finally {
    Remove-Item -LiteralPath $shortcutPath -Force -ErrorAction SilentlyContinue
}

Write-Output 'PASS: bootstrap syntax, automatic inspection, and no-launch check'

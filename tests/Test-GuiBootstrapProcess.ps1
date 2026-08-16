$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path $PSScriptRoot -Parent
$guiPath = Join-Path $root 'Antigravity稳定模式.ps1'
$bootstrapPath = Join-Path $root 'StableBootstrap.ps1'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntigravityGuiBootstrap-' + [guid]::NewGuid().ToString('N'))
$fakeBootstrapPath = Join-Path $temporaryRoot 'FakeBootstrap.ps1'
$runnerPath = Join-Path $temporaryRoot 'InvokeGuiBootstrap.ps1'

$tokens = $null
$errors = $null
$guiAst = [Management.Automation.Language.Parser]::ParseFile($guiPath, [ref]$tokens, [ref]$errors)
if ($errors.Count -ne 0) { throw "可视管理器语法错误：$errors" }
$invokeAst = $guiAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Invoke-BootstrapMode'
}, $true)
if ($null -eq $invokeAst) { throw '未找到 Invoke-BootstrapMode。' }
$processAst = $guiAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Invoke-CapturedProcess'
}, $true)
if ($null -eq $processAst) { throw '未找到公共异步进程执行器。' }

$bootstrapSource = [IO.File]::ReadAllText($bootstrapPath)
if (-not $bootstrapSource.Contains('[switch]$SuppressErrorDialog')) {
    throw 'Bootstrap 缺少禁止子进程错误弹框的参数。'
}
if (-not $bootstrapSource.Contains('[Console]::OutputEncoding')) {
    throw 'Bootstrap 未固定 UTF-8 错误输出。'
}
if (-not $bootstrapSource.Contains('[Console]::SetError')) {
    throw 'Bootstrap 未绑定 UTF-8 标准错误写入器。'
}

New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null
$fakeBootstrap = @'
param(
    [string]$InstallRoot,
    [string]$StateRoot,
    [string]$Mode,
    [switch]$SuppressErrorDialog
)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$standardError = [IO.StreamWriter]::new([Console]::OpenStandardError(), [Text.UTF8Encoding]::new($false))
$standardError.AutoFlush = $true
[Console]::SetError($standardError)
if (-not $SuppressErrorDialog) {
    [Console]::Error.WriteLine('SUPPRESS_SWITCH_MISSING')
    exit 31
}
[Console]::Error.Write(('x' * 1048576))
[Console]::Error.WriteLine('EXPECTED_FAKE_FAILURE_中文')
exit 23
'@
[IO.File]::WriteAllText($fakeBootstrapPath, $fakeBootstrap, [Text.UTF8Encoding]::new($false))

$functionSource = $invokeAst.Extent.Text
$runner = @"
`$ErrorActionPreference = 'Stop'
`$standardError = [IO.StreamWriter]::new([Console]::OpenStandardError(), [Text.UTF8Encoding]::new(`$false))
`$standardError.AutoFlush = `$true
[Console]::SetError(`$standardError)
`$bootstrapPath = '$($fakeBootstrapPath.Replace("'", "''"))'
`$projectRoot = '$($temporaryRoot.Replace("'", "''"))'
$($processAst.Extent.Text)
$functionSource
function Get-CompatibilityInstallStatus { throw '成功路径不应执行状态检查。' }
try {
    Invoke-BootstrapMode -Root 'D:\Fake Antigravity' -SelectedMode Stable -StopRunningProcesses | Out-Null
    exit 0
}
catch {
    [Console]::Error.WriteLine(`$_.Exception.Message)
    exit 17
}
"@
[IO.File]::WriteAllText($runnerPath, $runner, [Text.UTF8Encoding]::new($false))

$process = $null
try {
    $startInfo = [Diagnostics.ProcessStartInfo]::new('pwsh')
    $startInfo.ArgumentList.Add('-NoProfile')
    $startInfo.ArgumentList.Add('-File')
    $startInfo.ArgumentList.Add($runnerPath)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $startInfo.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    $process = [Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    if (-not $process.WaitForExit(10000)) {
        $process.Kill($true)
        $process.WaitForExit()
        throw 'GUI 等待 Bootstrap 超时，重定向输出仍可能死锁。'
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    if ($process.ExitCode -ne 17) { throw "GUI 子进程错误出口异常：$($process.ExitCode)`n$stdout`n$stderr" }
    if (-not $stderr.Contains('EXPECTED_FAKE_FAILURE_中文')) {
        $tail = $stderr.Substring([Math]::Max(0, $stderr.Length - 240))
        throw "GUI 未完整返回 Bootstrap 的 UTF-8 原始错误：$tail"
    }
    if ($stderr.Contains('SUPPRESS_SWITCH_MISSING')) { throw 'GUI 未禁止 Bootstrap 子进程弹框。' }
}
finally {
    if ($null -ne $process) {
        if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        $process.Dispose()
    }
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output 'PASS: GUI bootstrap errors are drained without deadlock or child dialogs'

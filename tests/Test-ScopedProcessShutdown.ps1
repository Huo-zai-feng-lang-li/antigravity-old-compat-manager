$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$modulePath = Join-Path $PSScriptRoot '..\scripts\StableMode.Core.psm1'
Import-Module $modulePath -Force

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntigravityProcessTest-' + [guid]::NewGuid().ToString('N'))
$firstRoot = Join-Path $temporaryRoot 'first'
$secondRoot = Join-Path $temporaryRoot 'second'
$processes = [Collections.Generic.List[Diagnostics.Process]]::new()

try {
    foreach ($root in @($firstRoot, $secondRoot)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $executable = Join-Path $root 'Antigravity.exe'
        Copy-Item -LiteralPath (Join-Path $env:SystemRoot 'System32\cmd.exe') -Destination $executable
        $processes.Add((Start-Process -FilePath $executable -ArgumentList '/c', 'ping -n 60 127.0.0.1 >nul' -WindowStyle Hidden -PassThru))
    }
    Start-Sleep -Milliseconds 300
    if ($processes[0].HasExited -or $processes[1].HasExited) { throw '测试进程未保持运行。' }

    & (Get-Module StableMode.Core) {
        param($Root)
        Stop-ScopedAntigravityProcesses -InstallRoot $Root
    } $firstRoot

    $processes[0].Refresh()
    $processes[1].Refresh()
    if (-not $processes[0].HasExited) { throw '所选安装目录进程未被关闭。' }
    if ($processes[1].HasExited) { throw '其他安装目录的同名进程被误伤。' }
    Write-Output 'PASS: scoped process shutdown closes only the selected Antigravity installation'
}
finally {
    foreach ($process in $processes) {
        try { if (-not $process.HasExited) { $process.Kill($true) } } catch { }
        $process.Dispose()
    }
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}

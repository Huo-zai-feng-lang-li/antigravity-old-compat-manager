[CmdletBinding()]
param(
    [string]$InstallRoot = 'D:\Antigravity',
    [ValidateRange(15, 180)]
    [int]$ObservationSeconds = 60,
    [ValidateRange(1, 65535)]
    [int]$CdpPort = 9000
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ScopedProcesses {
    param([Parameter(Mandatory)][string]$Root)

    $prefix = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    $executable = Join-Path $Root 'Antigravity.exe'
    $quotedExecutable = '"' + $executable + '"'
    @(Get-CimInstance Win32_Process | Where-Object {
        (-not [string]::IsNullOrWhiteSpace($_.ExecutablePath) -and
            $_.ExecutablePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) -or
        (-not [string]::IsNullOrWhiteSpace($_.CommandLine) -and
            ($_.CommandLine.StartsWith($executable, [StringComparison]::OrdinalIgnoreCase) -or
                $_.CommandLine.StartsWith($quotedExecutable, [StringComparison]::OrdinalIgnoreCase)))
    })
}

function Stop-ScopedProcesses {
    param([Parameter(Mandatory)][string]$Root)

    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        $running = @(Get-ScopedProcesses -Root $Root)
        if ($running.Count -eq 0) { return }
        $running | Sort-Object ProcessId -Descending | ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 500
    }
    $remaining = @(Get-ScopedProcesses -Root $Root)
    if ($remaining.Count -gt 0) {
        throw "无法清理 Antigravity 进程：$($remaining.ProcessId -join ', ')"
    }
}

function Get-MainWindowSample {
    param([Parameter(Mandatory)][object[]]$Processes)

    foreach ($processInfo in $Processes) {
        $process = Get-Process -Id $processInfo.ProcessId -ErrorAction SilentlyContinue
        if ($null -ne $process -and $process.MainWindowHandle -ne 0) {
            return [pscustomobject]@{
                ProcessId = $process.Id
                Handle = [int64]$process.MainWindowHandle
                Responding = $process.Responding
                Title = $process.MainWindowTitle
            }
        }
    }
    $null
}

function Read-SharedText {
    param([Parameter(Mandatory)][string]$Path)

    $stream = [IO.FileStream]::new(
        $Path,
        [IO.FileMode]::Open,
        [IO.FileAccess]::Read,
        [IO.FileShare]::ReadWrite
    )
    try {
        $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8, $true, 4096, $true)
        try { $reader.ReadToEnd() } finally { $reader.Dispose() }
    }
    finally {
        $stream.Dispose()
    }
}

$executable = Join-Path $InstallRoot 'Antigravity.exe'
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw "未找到 Antigravity：$executable"
}
$preexisting = @(Get-ScopedProcesses -Root $InstallRoot)
if ($preexisting.Count -gt 0) {
    throw "冷启动测试要求独占环境，已有进程：$($preexisting.ProcessId -join ', ')"
}

$logsRoot = Join-Path $env:APPDATA 'Antigravity\logs'
$startedLocal = Get-Date
$startedUtc = [DateTime]::UtcNow
$rootProcess = $null
$windowSeenAt = $null
$cdpSeenAt = $null
$maxUnresponsiveSeconds = 0.0
$unresponsiveSince = $null

try {
    $rootProcess = Start-Process -FilePath $executable -ArgumentList "--remote-debugging-port=$CdpPort" -PassThru
    $deadline = $startedLocal.AddSeconds($ObservationSeconds)
    while ((Get-Date) -lt $deadline) {
        $now = Get-Date
        $running = @(Get-ScopedProcesses -Root $InstallRoot)
        if ($running.Count -eq 0) { throw 'Antigravity 在观察期内提前退出。' }

        $window = Get-MainWindowSample -Processes $running
        if ($null -ne $window) {
            if ($null -eq $windowSeenAt) { $windowSeenAt = $now }
            if ($window.Responding) {
                if ($null -ne $unresponsiveSince) {
                    $duration = ($now - $unresponsiveSince).TotalSeconds
                    $maxUnresponsiveSeconds = [Math]::Max($maxUnresponsiveSeconds, $duration)
                    $unresponsiveSince = $null
                }
            } elseif ($null -eq $unresponsiveSince) {
                $unresponsiveSince = $now
            }
        }

        if ($null -eq $cdpSeenAt) {
            try {
                $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$CdpPort/json/list" -TimeoutSec 1
                if (@($targets).Count -gt 0) { $cdpSeenAt = $now }
            } catch { }
        }
        Start-Sleep -Milliseconds 500
    }

    if ($null -ne $unresponsiveSince) {
        $maxUnresponsiveSeconds = [Math]::Max($maxUnresponsiveSeconds, ((Get-Date) - $unresponsiveSince).TotalSeconds)
    }
    $logDirectory = Get-ChildItem -LiteralPath $logsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object LastWriteTime -ge $startedLocal.AddSeconds(-2) |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    $mainLog = if ($null -ne $logDirectory) { Join-Path $logDirectory.FullName 'main.log' } else { $null }
    $unresponsiveEventCount = if ($null -ne $mainLog -and (Test-Path -LiteralPath $mainLog)) {
        [regex]::Matches(
            (Read-SharedText -Path $mainLog),
            'CodeWindow.*unresponsive',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Count
    } else { 0 }
    $logDirectoryPath = if ($null -ne $logDirectory) { $logDirectory.FullName } else { $null }

    $result = [pscustomobject]@{
        StartedUtc = $startedUtc.ToString('O')
        RootProcessId = $rootProcess.Id
        WindowReadySeconds = if ($null -ne $windowSeenAt) { [Math]::Round(($windowSeenAt - $startedLocal).TotalSeconds, 2) } else { $null }
        CdpReadySeconds = if ($null -ne $cdpSeenAt) { [Math]::Round(($cdpSeenAt - $startedLocal).TotalSeconds, 2) } else { $null }
        MaxUnresponsiveSeconds = [Math]::Round($maxUnresponsiveSeconds, 2)
        CodeWindowUnresponsiveEvents = $unresponsiveEventCount
        LogDirectory = $logDirectoryPath
    }
    $result | ConvertTo-Json -Depth 4

    if ($null -eq $windowSeenAt) { throw '60 秒内未找到 Antigravity 主窗口。' }
    if ($null -eq $cdpSeenAt) { throw '60 秒内 CDP 未就绪。' }
    if ($maxUnresponsiveSeconds -ge 5) { throw "主窗口连续无响应 $maxUnresponsiveSeconds 秒。" }
    if ($unresponsiveEventCount -gt 0) { throw "检测到 $unresponsiveEventCount 条 CodeWindow unresponsive 事件。" }
    Write-Output 'PASS: Gemini37 cold start window remained responsive.'
}
finally {
    Stop-ScopedProcesses -Root $InstallRoot
}

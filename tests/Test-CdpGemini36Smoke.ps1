$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptPath = Join-Path $PSScriptRoot '..\tools\CdpGemini36Smoke.mjs'
$source = [IO.File]::ReadAllText($scriptPath)

foreach ($required in @(
    'cdpTimeoutMs',
    'failPending',
    'socket.addEventListener("close"',
    'pending.delete(id)',
    'baselineCount',
    'occurrences > baselineCount'
)) {
    if (-not $source.Contains($required)) { throw "CDP 3.6 冒烟缺少可靠性契约：$required" }
}

Write-Output 'PASS: CDP request timeout, disconnect cleanup, and new-response boundary anchors'

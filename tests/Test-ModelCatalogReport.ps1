[CmdletBinding()]
param([switch]$Live)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path $PSScriptRoot -Parent
$guiPath = Join-Path $root 'Antigravity稳定模式.ps1'
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($guiPath, [ref]$tokens, [ref]$errors)
if ($errors.Count -ne 0) { throw "可视管理器语法错误：$errors" }

function Get-GuiFunctionSource {
    param([string]$Name)
    $functionAst = $ast.Find({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $Name
    }, $true)
    if ($null -eq $functionAst) { throw "缺少函数：$Name" }
    $functionAst.Extent.Text
}

Invoke-Expression (Get-GuiFunctionSource 'Get-ModelCatalogReport')
$catalogProbePath = Join-Path $root 'tools\CdpModelCatalog.mjs'

if ($Live) {
    Invoke-Expression (Get-GuiFunctionSource 'Invoke-CapturedProcess')
    Invoke-Expression (Get-GuiFunctionSource 'Test-TcpPort')
    Invoke-Expression (Get-GuiFunctionSource 'Get-OfficialModelCatalog')
    Add-Type -AssemblyName System.Windows.Forms
    $officialCatalogPath = Join-Path $root 'tools\OfficialModelCatalog.mjs'
} else {
    function Get-OfficialModelCatalog {
        [pscustomobject]@{
            source = 'https://antigravity.google/docs/models'
            fetchedAt = '2026-08-14T00:00:00Z'
            models = @('Gemini 3.7 Flash', 'Claude Sonnet 4.6 (thinking)')
        }
    }
    function Test-TcpPort { $false }
}

$report = Get-ModelCatalogReport
foreach ($required in @(
    '官方公开推理模型',
    'Gemini 3.7 Flash',
    'https://antigravity.google/docs/models',
    'Gemini 3.8 已通过兼容名单放行',
    '旧版 IDE 当前可见模型'
)) {
    if (-not $report.Contains($required)) { throw "模型目录报告缺少：$required" }
}
if ($Live) { Write-Output $report }
Write-Output 'PASS: model catalog report separates official and legacy-visible models'

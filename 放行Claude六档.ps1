#requires -Version 5.1
<#
.SYNOPSIS
  一键给锁死的旧版 Antigravity（D:\Antigravity）workbench 应用/撤销模型放行补丁
  （幂等，可重复运行）。当前 MODELS 为空 → 直接把 wb 还原为干净基线，下拉与官方原生一致。

.DESCRIPTION
  - 从干净 Gemini37 补丁态基线 model-unlock\assets\prod-wb-pre-claude.js 还原，再按
    model-unlock\patch-workbench.mjs 顶部的 MODELS 映射表注入下拉项与选择旁路。
  - 后端改道在 zk 扩展（/__agtarget + _agReadSelected），本脚本只改前端 workbench。
  - 未来放行新模型：只改 model-unlock\patch-workbench.mjs 顶部 MODELS 一行，再重跑本脚本。
  - 工具链说明见 model-unlock\README.md，原理与完整步骤见 SOP-新模型放行.md。
  - 详见 SOP-新模型放行.md。

.PARAMETER ForceKill
  运行前自动关闭 Antigravity 与 language_server（默认不自动关，检测到进程则中止）。

.EXAMPLE
  pwsh -File .\放行Claude六档.ps1 -ForceKill
#>
[CmdletBinding()]
param(
  [switch]$ForceKill
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$patch = Join-Path $root "model-unlock\patch-workbench.mjs"
$wb = "D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js"

if (-not (Test-Path $patch)) { throw "找不到补丁脚本：$patch" }
if (-not (Test-Path $wb)) { throw "找不到 workbench：$wb（确认 Antigravity 装在 D:\Antigravity）" }

function Get-AgState {
  $ag = @(Get-Process Antigravity -ErrorAction SilentlyContinue).Count
  $ls = @(Get-Process | Where-Object { $_.ProcessName -match "language_server" -and $_.Path -like "D:\Antigravity\*" }).Count
  return [pscustomobject]@{ Ag = $ag; Ls = $ls }
}

$st = Get-AgState
if ($st.Ag -gt 0 -or $st.Ls -gt 0) {
  if (-not $ForceKill) {
    Write-Warning "检测到 Antigravity/language_server 仍在运行（ag=$($st.Ag) ls=$($st.Ls)）。请先完全退出，或用 -ForceKill 由脚本关闭后重试。"
    return
  }
  Write-Host "关闭 Antigravity / language_server ..." -ForegroundColor Yellow
  Get-Process Antigravity -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Get-Process | Where-Object { $_.ProcessName -match "language_server" -and $_.Path -like "D:\Antigravity\*" } | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 7
  $st = Get-AgState
  if ($st.Ag -gt 0) { Get-Process Antigravity -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Seconds 5 }
}

$node = (Get-Command node -ErrorAction SilentlyContinue)
if (-not $node) { throw "未找到 node，请先安装 Node.js 或用项目自带环境。" }

Write-Host "应用 workbench 模型放行补丁（幂等：先还原干净 Gemini37 态再注入）..." -ForegroundColor Cyan
& node $patch
if ($LASTEXITCODE -ne 0) { throw "补丁脚本失败（exit=$LASTEXITCODE），workbench 已被还原为干净基线，未注入半成品。" }

$final = Get-AgState
$modes = (Select-String -Path $patch -Pattern "uid: '.*'" | Measure-Object).Count
if ($modes -eq 0) {
  Write-Host "完成。当前 ag=$($final.Ag) ls=$($final.Ls)。MODELS 为空，下拉已还原为官方原生状态（当前 Gemini 3.8 + Claude 4.6），启动默认 Gemini 3.8 Flash (High)。" -ForegroundColor Green
} else {
  Write-Host "完成。当前 ag=$($final.Ag) ls=$($final.Ls)。MODELS 非空（共 $modes 项），下拉已注入合成项（当前 Gemini 3.8 + Claude 5.5 六档），启动仍默认 Gemini 3.8 Flash (High)，手动切换至 Claude 档即用。" -ForegroundColor Green
}

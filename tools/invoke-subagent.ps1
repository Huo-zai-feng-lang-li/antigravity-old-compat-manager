<#
.SYNOPSIS
  反重力 IDE 子代理调用脚本
.DESCRIPTION
  主代理通过 run_command 调用此脚本，在独立 CLI 会话中执行任务，返回结果。
  模拟干净会话的子代理效果：无上下文污染、独立执行、返回最终结果。
.PARAMETER Task
  给子代理的完整任务描述
.PARAMETER AgentType
  使用哪个 CLI: claude / codex (默认 claude)
.PARAMETER Timeout
  超时秒数 (默认 120)
.EXAMPLE
  pwsh -File invoke-subagent.ps1 -Task "审计 src/auth.ts 的安全漏洞" -AgentType claude
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Task,
    
    [string]$AgentType = "claude",
    
    [int]$Timeout = 120
)

$ErrorActionPreference = 'Stop'

Write-Host "=== 子代理启动 ===" -ForegroundColor Cyan
Write-Host "类型: $AgentType"
Write-Host "任务: $Task"
Write-Host "超时: ${Timeout}s"
Write-Host ""

# 根据类型选择命令
switch ($AgentType) {
    "claude" {
        $cmd = "claude"
        $args = @("-p", $Task)
    }
    "codex" {
        $cmd = "codex"
        $args = @("exec", $Task)
    }
    default {
        $cmd = "claude"
        $args = @("-p", $Task)
    }
}

Write-Host "执行: $cmd $Task" -ForegroundColor Gray
Write-Host ""

try {
    $output = & $cmd -p $Task 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    
    Write-Host "=== 子代理结果 ===" -ForegroundColor Green
    Write-Host $output
    Write-Host ""
    Write-Host "退出码: $exitCode" -ForegroundColor $(if ($exitCode -eq 0) {'Green'} else {'Red'})
    
    exit $exitCode
} catch {
    Write-Host "=== 子代理错误 ===" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

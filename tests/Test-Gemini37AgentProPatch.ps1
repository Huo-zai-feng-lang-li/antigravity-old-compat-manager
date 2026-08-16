$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot '..\scripts\StableMode.Core.psm1') -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

$source = @'
#!/usr/bin/env node
"use strict";
const net = require("net");
async function handler(req, res) {
    let _eaBody = body;
    _eaHotReload();
    _eaDiag("#" + rid + " routing-check: _ea=" + !!_ea + " kind=" + kind);
    proxyToCloud(req, res, _eaBody, rid);
}
'@

$patched = ConvertTo-Gemini37AgentProSourceContent -Content $source
Assert-True (Test-Gemini37AgentProSourceContent -Content $patched) '代理源补丁结构应通过'
Assert-True ($patched.Contains('require("./_ag-gemini37-compat.cjs")')) '代理必须加载 repo-owned helper'
Assert-True ($patched.Contains('kind === "GEMINI_REST_CHAT"')) '改写必须限制为 Gemini REST chat'
Assert-True ($patched.Contains('rewriteRequestBody(_eaBody)')) '代理必须在官方转发前改写 body'
Assert-True (-not $patched.Contains('request.contents')) '代理源补丁不得记录或读取提示词'
Assert-True ($patched -eq (ConvertTo-Gemini37AgentProSourceContent -Content $patched)) '代理补丁重复应用必须幂等'
Assert-True ($source -eq (ConvertTo-StableAgentProSourceContent -Content $patched)) '代理补丁必须可精确回退'

Write-Output 'PASS: Agent Pro source patch is scoped, idempotent, and reversible'

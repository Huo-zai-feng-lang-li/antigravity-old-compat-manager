$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$modulePath = Join-Path $PSScriptRoot '..\scripts\StableMode.Core.psm1'
Import-Module $modulePath -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) { throw "ASSERT: $Message; expected=[$Expected], actual=[$Actual]" }
}

$modelAnchor = 'function n9a(e,t,r,n){return ct(oS,{cascadeModelConfigData:r9a(e),disableTelemetry:!(t.telemetryEnabled??!1),userDataCollectionForceDisabled:t.userDataCollectionForceDisabled??!1,name:r.name,email:r.email,userTier:n.userTier})}'
$cacheAnchor = 'return a},persist:async(e,t)=>{const r=e.get(Gi);await r.whenReady;const n=La(ea,t);r.store(AMe,n,-1,0)}}'
$endpointAnchor = 'const g=this.j.getState("uss-lsClientMachineInfos"),b=ZBa(g),R={host:"127.0.0.1",resource:"",port:p.httpsPort,csrfToken:n,homeDir:_Ba()};b.some(A=>A.port===p.httpsPort&&A.csrfToken===n)||(b.push(R),this.j.pushUpdate(GBa(b))),await this.a.initialize(p.httpsPort,n)'
$spawnAnchor = 'const n=XBa(),a=qZr(this.b,n,this.m,this.n);this.f.info(`[LS Main] Args: ${a.join(" ")}`);'
$raw = @($modelAnchor, $cacheAnchor, $endpointAnchor, $spawnAnchor) -join '|'

$patched = ConvertTo-StableMainContent -Content $raw
Assert-True ($patched.Contains('const _agOneLSAgentProxy=async(')) '必须安装 OneLS Agent Pro 桥接器'
Assert-True ($patched.Contains('dao-one-ls-agent-pro.cjs')) '必须从 appRoot 动态加载纯桥接模块'
Assert-True ($patched.Contains('new URL("../dao-one-ls-agent-pro.cjs",import.meta.url)')) '桥接路径必须相对 main.js URL 解析以兼容空格路径'
Assert-True ($patched.Contains('.waitForAgentProxy({timeoutMs:1e4})')) '共享 LS 启动前最多等待 10 秒'
Assert-True ($patched.Contains('indexOf("--cloud_code_endpoint")')) '必须只定位官方云端点参数'
Assert-True ($patched.Contains('/^http:\/\/127\.0\.0\.1:\d+$/')) '只允许回环 HTTP 代理端点'
Assert-True ($patched.Contains('t[s+1]=n')) '代理健康时只替换云端点值'
Assert-True ($patched.Contains('await _agOneLSAgentProxy(this.f,a);this.f.info(`[LS Main] Args:')) '必须在共享 LS spawn 日志前等待桥接结果'
Assert-True (-not $patched.Contains('source.js')) '主进程不得加载 Agent Pro source.js'
Assert-Equal $patched (ConvertTo-StableMainContent -Content $patched) 'OneLS 桥接补丁必须幂等'
Assert-True (Test-StableMainContent -Content $patched) '桥接后的 main 结构检查必须通过'

$helperStart = $patched.IndexOf('const _agOneLSAgentProxy=async(', [StringComparison]::Ordinal)
$spawnStart = $patched.IndexOf('const n=XBa()', $helperStart, [StringComparison]::Ordinal)
Assert-True ($helperStart -ge 0 -and $spawnStart -gt $helperStart) '必须能提取完整桥接器做运行验证'
$helper = $patched.Substring($helperStart, $spawnStart - $helperStart)
$runtimeRoot = Join-Path ([IO.Path]::GetTempPath()) ("AntigravityOneLS-$([guid]::NewGuid().ToString('N'))")
$runtimeOut = Join-Path $runtimeRoot 'out'
$runnerPath = Join-Path $runtimeOut 'main.mjs'
$bridgePath = Join-Path $runtimeRoot 'dao-one-ls-agent-pro.cjs'
try {
    [IO.Directory]::CreateDirectory($runtimeOut) | Out-Null
    [IO.File]::WriteAllText($bridgePath, 'module.exports={waitForAgentProxy:async()=>process.env.AG_TEST_ENDPOINT||null};', [Text.UTF8Encoding]::new($false))
    $runner = @"
$helper
const logger={info(){},warn(){}};
process.env.AG_TEST_ENDPOINT='http://127.0.0.1:18889';
const proxied=['--cloud_code_endpoint','https://official.example'];
if(!await _agOneLSAgentProxy(logger,proxied)||proxied[1]!==process.env.AG_TEST_ENDPOINT)throw new Error('valid endpoint was not applied');
process.env.AG_TEST_ENDPOINT='https://127.0.0.1:18889';
const invalid=['--cloud_code_endpoint','https://official.example'];
if(await _agOneLSAgentProxy(logger,invalid)||invalid[1]!=='https://official.example')throw new Error('invalid endpoint changed official fallback');
delete process.env.AG_TEST_ENDPOINT;
const unavailable=['--cloud_code_endpoint','https://official.example'];
if(await _agOneLSAgentProxy(logger,unavailable)||unavailable[1]!=='https://official.example')throw new Error('unavailable proxy changed official fallback');
"@
    [IO.File]::WriteAllText($runnerPath, $runner, [Text.UTF8Encoding]::new($false))
    & (Get-Command node -ErrorAction Stop).Source $runnerPath
    Assert-True ($LASTEXITCODE -eq 0) '桥接运行验证必须通过：有效回环端点替换，异常端点保留官方回退'
}
finally {
    Remove-Item -LiteralPath $runtimeRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$missingSpawnRejected = $false
try { ConvertTo-StableMainContent -Content (@($modelAnchor, $cacheAnchor, $endpointAnchor) -join '|') | Out-Null }
catch { $missingSpawnRejected = $true }
Assert-True $missingSpawnRejected '新版本缺失共享 LS spawn 锚点时必须 fail-closed'

$duplicateSpawnRejected = $false
try { ConvertTo-StableMainContent -Content (@($modelAnchor, $cacheAnchor, $endpointAnchor, $spawnAnchor, $spawnAnchor) -join '|') | Out-Null }
catch { $duplicateSpawnRejected = $true }
Assert-True $duplicateSpawnRejected '共享 LS spawn 锚点重复时必须 fail-closed'

Write-Output 'PASS: OneLS Agent Pro bridge injection, fallback structure, idempotency, and fail-closed anchors'

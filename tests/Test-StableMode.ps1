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
    if ($Expected -ne $Actual) {
        throw "ASSERT: $Message; expected=[$Expected], actual=[$Actual]"
    }
}

$rawBoundary = 'async pushUpdate(t){if(!Object.hasOwn(UGe,t.topicName))throw new Error(`Invalid topic: ${t.topicName}`);const r=t.appliedUpdate;'
$rawMain = @(
    $rawBoundary
    'y={host:"127.0.0.1",resource:"",port:f.httpsPort,csrfToken:a,homeDir:sUs()};b.some(v=>v.port===f.httpsPort&&v.csrfToken===a)'
    'await this.a.initialize(f.httpsPort,a)'
) -join '|'

$stableMain = ConvertTo-StableMainContent -Content $rawMain
Assert-True (-not $stableMain.Contains('Gemini 3.5 Flash')) '稳定名单应隐藏 Gemini 3.5'
Assert-True ($stableMain.Contains('Claude Sonnet 4.6 (Thinking)')) '稳定名单应保留 Claude'
Assert-True (-not $stableMain.Contains('Gemini 3.6 Flash (High)')) '稳定名单不得注入 Gemini 3.6'
Assert-True ($stableMain.Contains('}catch{return}const r=t.appliedUpdate;')) '解析失败必须 fail-closed'
Assert-True ($stableMain.Contains('port:f.httpPort')) '渲染端应收到本地 HTTP 端口'
Assert-True ($stableMain.Contains('initialize(f.httpsPort')) '主进程语言服务器仍使用 HTTPS 初始化端口'
Assert-Equal $stableMain (ConvertTo-StableMainContent -Content $stableMain) '重复应用必须幂等'

$rawWorkbench = 'before|get baseUrl(){return`https://127.0.0.1:${this.port}`}|after'
$stableWorkbench = ConvertTo-StableWorkbenchContent -Content $rawWorkbench -Adapter 'legacy-http-v1'
Assert-True ($stableWorkbench.Contains('get baseUrl(){return`http://127.0.0.1:${this.port}`}')) '工作台必须访问本地 HTTP'
Assert-Equal $stableWorkbench (ConvertTo-StableWorkbenchContent -Content $stableWorkbench -Adapter 'legacy-http-v1') '工作台重复应用必须幂等'

Assert-True (Test-StableMainContent -Content $stableMain) '稳定 main 结构检查应通过'
Assert-True (Test-StableWorkbenchContent -Content $stableWorkbench -Adapter 'legacy-http-v1') '稳定 workbench 结构检查应通过'

$newModelAnchor = 'function n9a(e,t,r,n){return ct(oS,{cascadeModelConfigData:r9a(e),disableTelemetry:!(t.telemetryEnabled??!1),userDataCollectionForceDisabled:t.userDataCollectionForceDisabled??!1,name:r.name,email:r.email,userTier:n.userTier})}'
$newCacheAnchor = 'return a},persist:async(e,t)=>{const r=e.get(Gi);await r.whenReady;const n=La(ea,t);r.store(AMe,n,-1,0)}}'
$newRawMain = @(
    $newModelAnchor
    $newCacheAnchor
    'const g=this.j.getState("uss-lsClientMachineInfos"),b=ZBa(g),R={host:"127.0.0.1",resource:"",port:p.httpsPort,csrfToken:n,homeDir:_Ba()};b.some(A=>A.port===p.httpsPort&&A.csrfToken===n)||(b.push(R),this.j.pushUpdate(GBa(b))),await this.a.initialize(p.httpsPort,n)'
    'const n=XBa(),a=qZr(this.b,n,this.m,this.n);this.f.info(`[LS Main] Args: ${a.join(" ")}`);'
) -join '|'
$newStableMain = ConvertTo-StableMainContent -Content $newRawMain
$newStableWorkbench = ConvertTo-StableWorkbenchContent -Content $rawWorkbench -Adapter 'catalog-filter-http-v2'
Assert-True ($newStableMain.Contains('port:p.httpPort,csrfToken:n,homeDir:_Ba()')) '新模型目录必须向 renderer 发布 HTTP 端口'
Assert-True ($newStableMain.Contains('initialize(p.httpsPort,n)')) '主进程内部客户端仍使用 HTTPS 初始化端口'
Assert-True ($newStableMain.Contains('b=ZBa(g).filter(A=>A.resource!=="")')) '必须清除旧的本机 LS 端点缓存'
Assert-True (-not $newStableMain.Contains('b.some(A=>A.port===p.httpsPort')) '不得用旧 HTTPS 端口做缓存命中判断'
Assert-True ($newStableMain.Contains('await _agOneLSAgentProxy(this.f,a)')) '共享 LS 启动前必须等待 Agent Pro 桥接'
Assert-True ($newStableWorkbench.Contains('get baseUrl(){return`http://127.0.0.1:${this.port}`}')) '新模型目录 workbench 必须使用 HTTP'
Assert-True (Test-StableWorkbenchContent -Content $newStableWorkbench -Adapter 'catalog-filter-http-v2') '新适配器 HTTP 结构检查应通过'
$mispatchedNewMain = $newStableMain.Replace('port:p.httpPort,csrfToken:n,homeDir:_Ba()', 'port:p.httpsPort,csrfToken:n,homeDir:_Ba()')
Assert-Equal $newStableMain (ConvertTo-StableMainContent -Content $mispatchedNewMain) '新适配器必须迁移旧 HTTPS main 补丁'
Assert-True (Test-StableMainContent -Content $newStableMain) '新版本双边界稳定结构检查应通过'

$dualTransportWorkbench = @(
    'cIo=class{constructor(t,e){this.port=t,this.csrfToken=e}get baseUrl(){return`https://127.0.0.1:${this.port}`}}'
    'async C(){const e="";this.n=new cIo(o.port,o.csrfToken)}'
    'async F(){this.n=new cIo(i,n)}'
) -join '|'
$stableDualTransport = ConvertTo-StableWorkbenchContent -Content $dualTransportWorkbench -Adapter 'catalog-dual-transport-v3'
Assert-True ($stableDualTransport.Contains('constructor(t,e,i=!1){this.port=t,this.csrfToken=e,this.useHttp=i}')) '双协议客户端必须记录传输模式'
Assert-True ($stableDualTransport.Contains('get baseUrl(){return`${this.useHttp?"http":"https"}://127.0.0.1:${this.port}`}')) '客户端必须按链路选择协议'
Assert-True ($stableDualTransport.Contains('this.n=new cIo(o.port,o.csrfToken,!0)')) 'USS 单实例链路必须使用 HTTP'
Assert-True ($stableDualTransport.Contains('async F(){this.n=new cIo(i,n)}')) '扩展宿主直连链路必须保留 HTTPS'
Assert-True (Test-StableWorkbenchContent -Content $stableDualTransport -Adapter 'catalog-dual-transport-v3') '双协议结构检查应通过'
Assert-Equal $stableDualTransport (ConvertTo-StableWorkbenchContent -Content $stableDualTransport -Adapter 'catalog-dual-transport-v3') '双协议补丁必须幂等'

$unknownAdapterRejected = $false
try { ConvertTo-StableWorkbenchContent -Content $rawWorkbench -Adapter 'unknown-v9' | Out-Null }
catch { $unknownAdapterRejected = $true }
Assert-True $unknownAdapterRejected '未知 workbench 适配器必须 fail-closed'

$sqlite = Get-Command sqlite3 -ErrorAction Stop
$cacheDatabase = Join-Path ([IO.Path]::GetTempPath()) ("AntigravityCache-$([guid]::NewGuid().ToString('N')).vscdb")
try {
    & $sqlite.Source $cacheDatabase "CREATE TABLE ItemTable (key TEXT UNIQUE, value BLOB); INSERT INTO ItemTable VALUES ('antigravityUnifiedStateSync.oauthToken', X'0001'), ('antigravityUnifiedStateSync.userStatus', X'0102'), ('antigravityUnifiedStateSync.modelPreferences', X'0304'), ('unrelated', X'0506');"
    Clear-StableModelCache -DatabasePath $cacheDatabase | Out-Null
    Assert-Equal '1' (& $sqlite.Source $cacheDatabase "SELECT count(*) FROM ItemTable WHERE key='antigravityUnifiedStateSync.oauthToken';") '清缓存必须保留 oauthToken'
    Assert-Equal '1' (& $sqlite.Source $cacheDatabase "SELECT count(*) FROM ItemTable WHERE key='antigravityUnifiedStateSync.userStatus';") '清缓存必须保留 userStatus'
    Assert-Equal '0' (& $sqlite.Source $cacheDatabase "SELECT count(*) FROM ItemTable WHERE key='antigravityUnifiedStateSync.modelPreferences';") '清缓存必须删除 modelPreferences'
    Assert-Equal '1' (& $sqlite.Source $cacheDatabase "SELECT count(*) FROM ItemTable WHERE key='unrelated';") '清缓存不得影响无关状态'
}
finally {
    Remove-Item -LiteralPath $cacheDatabase -Force -ErrorAction SilentlyContinue
}

$unknownRejected = $false
try { ConvertTo-StableMainContent -Content 'unknown-content' | Out-Null }
catch { $unknownRejected = $true }
Assert-True $unknownRejected '未知 main 结构必须拒绝'

$unknownHashRejected = $false
try {
    & (Get-Module StableMode.Core) {
        $source = [pscustomobject]@{ Main = 'BAD-MAIN'; Workbench = 'BAD-WORKBENCH' }
        Assert-CompatibilitySourceAllowed -Source $source -PreviousMode Stable
    }
} catch { $unknownHashRejected = $true }
Assert-True $unknownHashRejected '非自适应模式不得因结构被识别为 Stable 而绕过固定来源哈希门禁'

$currentMainPath = 'D:\Antigravity\resources\app\out\main.js'
if ((Test-Path -LiteralPath $currentMainPath) -and
    (Get-FileHash -LiteralPath $currentMainPath -Algorithm SHA256).Hash -eq '4A91118CECAAD47C30867DF082EF9920B79CB051DE910A75E75F086191577FB3') {
    $currentCandidate = ConvertTo-StableMainContent ([IO.File]::ReadAllText($currentMainPath))
    $candidateBytes = [Text.UTF8Encoding]::new($false).GetBytes($currentCandidate)
    $candidateHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($candidateBytes))
    Assert-Equal '4559D1A3371D5497B7CDB27D5F0446EC4357B6A193BBB75526DE8E7F2C08BF8D' $candidateHash '新版本候选哈希'
    Assert-True (Test-StableMainContent $currentCandidate) '新版本双边界稳定结构检查应通过'
}

Write-Output 'PASS: stable mode transformations, fail-closed policy, idempotency, and unknown-input rejection'

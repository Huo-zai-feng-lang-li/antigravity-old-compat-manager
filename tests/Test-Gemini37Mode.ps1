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

$rawMain = @(
    'async pushUpdate(t){if(!Object.hasOwn(UGe,t.topicName))throw new Error(`Invalid topic: ${t.topicName}`);const r=t.appliedUpdate;'
    'y={host:"127.0.0.1",resource:"",port:f.httpsPort,csrfToken:a,homeDir:sUs()};b.some(v=>v.port===f.httpsPort&&v.csrfToken===a)'
    'await this.a.initialize(f.httpsPort,a)'
) -join '|'
$stableMain = ConvertTo-StableMainContent -Content $rawMain

$qbAnchor = 'qb(e){if(e.choice.case!=="model")return;const i=Jku(e.choice.value);this.db.pushUpdate(i)}'
$dbAnchor = 'async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}'
$modelOptionAnchor = 'Qun=t=>{if(!t.modelOrAlias)return null;let e=t.modelOrAlias.choice.case==="model"?t.modelOrAlias.choice.value:oz.UNSPECIFIED,i=t.modelOrAlias.choice.case==="alias"?t.modelOrAlias.choice.value:void 0;return{label:t.label,value:e'
$requestedModel = 'requestedModel:this.m,customModelInfoOverride:this.n'
$rawWorkbench = @(
    'get baseUrl(){return`https://127.0.0.1:${this.port}`}'
    $qbAnchor
    $dbAnchor
    $modelOptionAnchor
    $requestedModel
) -join '|'
$stableWorkbench = ConvertTo-StableWorkbenchContent -Content $rawWorkbench -Adapter 'legacy-http-v1'

$geminiMain = ConvertTo-Gemini37MainContent -Content $stableMain
$geminiWorkbench = ConvertTo-Gemini37WorkbenchContent -Content $stableWorkbench

$newModelAnchor = 'function n9a(e,t,r,n){return ct(oS,{cascadeModelConfigData:r9a(e),disableTelemetry:!(t.telemetryEnabled??!1),userDataCollectionForceDisabled:t.userDataCollectionForceDisabled??!1,name:r.name,email:r.email,userTier:n.userTier})}'
$newModelConfigAnchor = 'modelOrAlias:ct(INe,{choice:{case:"model",value:t.model}})'
$newDefaultModelAnchor = 's=ct(pIt,{modelOrAlias:ct(INe,{choice:{case:"model",value:d.model}})})'
$newCacheAnchor = 'return a},persist:async(e,t)=>{const r=e.get(Gi);await r.whenReady;const n=La(ea,t);r.store(AMe,n,-1,0)}}'
$newRawMain = @(
    $newModelConfigAnchor
    $newDefaultModelAnchor
    $newModelAnchor
    $newCacheAnchor
    'const g=this.j.getState("uss-lsClientMachineInfos"),b=ZBa(g),R={host:"127.0.0.1",resource:"",port:p.httpsPort,csrfToken:n,homeDir:_Ba()};b.some(A=>A.port===p.httpsPort&&A.csrfToken===n)||(b.push(R),this.j.pushUpdate(GBa(b))),await this.a.initialize(p.httpsPort,n)'
    'const n=XBa(),a=qZr(this.b,n,this.m,this.n);this.f.info(`[LS Main] Args: ${a.join(" ")}`);'
) -join '|'
$newStableMain = ConvertTo-StableMainContent -Content $newRawMain
$newGeminiMain = ConvertTo-Gemini37MainContent -Content $newStableMain
Assert-True (-not $newGeminiMain.Contains('_agStableStartupLabels')) '3.7 目录不得注入破坏模型列表的默认集合'
Assert-True ($newGeminiMain.Contains('modelOrAlias:ct(INe,{choice:t.model?{case:"model",value:t.model}:t.recommended?{case:"alias",value:8}:{case:"model",value:0}})')) '推荐的新模型必须映射到旧协议 RECOMMENDED alias'
Assert-True ($newGeminiMain.Contains('s=ct(pIt,{modelOrAlias:ct(INe,{choice:d.model?{case:"model",value:d.model}:d.recommended?{case:"alias",value:8}:{case:"model",value:0}})})')) '默认推荐模型必须映射到旧协议 RECOMMENDED alias'
Assert-True (-not $newGeminiMain.Contains('{case:"alias",value:e}')) '不得把字符串模型键写入 int32 alias 字段'
Assert-True ($newGeminiMain.Contains('r.modelOrAlias.choice.value===0')) '旧缓存中的 Gemini 3.7 model=0 条目必须先隔离'
Assert-True ($newGeminiMain.Contains('_agSeenChoices')) '同一 model/alias choice 的重复模型必须去重'
Assert-True ($newGeminiMain.Contains('map(a=>`${a.case}:${a.value}`)')) '默认覆盖校验必须同时支持 model 与 alias'
Assert-True (-not $newGeminiMain.Contains('/^Gemini 3\.7(?: |$)/.test(i?.label??"")')) '不得清除有效的 Gemini 3.7 alias 默认值'
Assert-True (-not $newGeminiMain.Contains('t.defaultOverrideModelConfig=i')) '3.7 不得把完整模型配置强写为默认值'
Assert-Equal $newStableMain (ConvertTo-StableMainContent -Content $newGeminiMain) '新模型目录 3.7 main 必须可精确回退'
Assert-Equal $newGeminiMain (ConvertTo-Gemini37MainContent -Content $newGeminiMain) '新模型目录 3.7 main 重复应用必须幂等'

foreach ($label in @(
    'Claude Sonnet 4.6 (Thinking)',
    'Claude Opus 4.6 (Thinking)',
    'Gemini 3.8 Flash (High)'
)) {
    Assert-True ($geminiMain.Contains($label)) "兼容名单必须包含 $label"
}
Assert-True (-not $geminiMain.Contains('Gemini 3.6 Flash')) '兼容名单不得包含 Gemini 3.6 Flash'
Assert-True (-not $geminiMain.Contains('Gemini 3.7 Flash')) '兼容名单必须隐藏 Gemini 3.7 Flash'
Assert-True (-not $geminiMain.Contains('Gemini 3.8 Flash (Medium)')) '兼容名单必须隐藏 Gemini 3.8 Medium'
Assert-True (-not $geminiMain.Contains('Gemini 3.8 Flash (Low)')) '兼容名单必须隐藏 Gemini 3.8 Low'
Assert-True (-not $geminiMain.Contains('Claude Sonnet 4.6 (thinking)')) '兼容名单不得混入大小写重复的 Claude 标签'
Assert-True (-not $geminiMain.Contains('Claude Opus 4.6 (thinking)')) '兼容名单不得混入大小写重复的 Claude 标签'
Assert-True ($geminiWorkbench.Contains('_agGemini36Ids=new Set([1264,1265])')) '组合模式必须复用已验证的 3.6 固定 ID 持久化'
Assert-True ($geminiWorkbench.Contains('_agGemini37PreferenceKey')) '3.7 Workbench 必须持久化 alias 8 选择'
Assert-True ($geminiWorkbench.Contains('requestedModel:this.m')) '发送链必须保留真实 requestedModel'
Assert-True (Test-Gemini37MainContent -Content $geminiMain) '3.7 main 结构检查应通过'
Assert-True (Test-Gemini37WorkbenchContent -Content $geminiWorkbench) '组合模式 Workbench 结构检查应通过'
Assert-Equal 'Gemini37' (Get-InstalledCompatibilityMode -MainContent $geminiMain -WorkbenchContent $geminiWorkbench) '模式应识别为 Gemini37'
Assert-Equal $stableMain (ConvertTo-StableMainContent -Content $geminiMain) '3.7 main 必须可精确回退'
Assert-Equal $stableWorkbench (ConvertTo-StableWorkbenchContent -Content $geminiWorkbench -Adapter 'legacy-http-v1') '3.7 workbench 必须可精确回退'

$legacyPrefix = 'const _agCompatibilityMode="gemini37-v1",_agGemini37Ids=new Set,_agGemini37PreferenceKey="antigravity.compat.gemini37.preference.v1";function _agRememberGemini37(e,t){if(typeof e==="string"&&/^Gemini 3\.7(?: |$)/.test(e)&&!/\(Low\)$/.test(e)&&Number.isInteger(t))_agGemini37Ids.add(t)}function _agWriteGemini37(e){try{localStorage.setItem(_agGemini37PreferenceKey,String(e))}catch{}}function _agClearGemini37(){try{localStorage.removeItem(_agGemini37PreferenceKey)}catch{}}function _agReadGemini37(){try{const e=Number(localStorage.getItem(_agGemini37PreferenceKey));return Number.isInteger(e)&&_agGemini37Ids.has(e)?e:void 0}catch{return void 0}}'
$legacyQb = 'qb(e){if(e.choice.case!=="model")return;const i=e.choice.value;if(_agGemini37Ids.has(i)){_agWriteGemini37(i);return}_agClearGemini37();const n=Jku(i);this.db.pushUpdate(n)}'
$legacyDb = 'async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=_agReadGemini37()??Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}'
$legacyOption = $modelOptionAnchor.Replace('return{label:t.label,value:e', '_agRememberGemini37(t.label,e);return{label:t.label,value:e', [StringComparison]::Ordinal)
$legacyGeminiWorkbench = $legacyPrefix + $stableWorkbench
$legacyGeminiWorkbench = $legacyGeminiWorkbench.Replace($qbAnchor, $legacyQb, [StringComparison]::Ordinal)
$legacyGeminiWorkbench = $legacyGeminiWorkbench.Replace($dbAnchor, $legacyDb, [StringComparison]::Ordinal)
$legacyGeminiWorkbench = $legacyGeminiWorkbench.Replace($modelOptionAnchor, $legacyOption, [StringComparison]::Ordinal)
Assert-Equal $stableWorkbench (ConvertTo-StableWorkbenchContent -Content $legacyGeminiWorkbench -Adapter 'legacy-http-v1') '旧 3.7 workbench 必须可精确回退'
Assert-Equal $stableWorkbench (ConvertTo-StableWorkbenchContent -Content $legacyGeminiWorkbench -Adapter 'legacy-http-v1') '旧 3.7 workbench 必须迁移为原生 Stable'

$currentAllowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.8 Flash (High)"]'
$legacyAllowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Claude Sonnet 4.6 (thinking)","Claude Opus 4.6 (thinking)","Gemini 3.7 Flash","Gemini 3.7 Flash (High)","Gemini 3.7 Flash (Medium)"]'
$legacyGeminiMain = $geminiMain.Replace($currentAllowlist, $legacyAllowlist, [StringComparison]::Ordinal)
Assert-Equal 'Gemini37' (Get-InstalledCompatibilityMode -MainContent $legacyGeminiMain -WorkbenchContent $stableWorkbench) 'v6 主文件加原生 Workbench 必须识别为 Gemini37 迁移态'

Write-Output 'PASS: Gemini 3.7 recommended alias, Gemini 3.6 coexistence, fixed workbench persistence, and reversibility'

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$modulePath = Join-Path $PSScriptRoot '..\scripts\StableMode.Core.psm1'
Import-Module $modulePath -Force
$module = Get-Module StableMode.Core

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

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    $thrown = $false
    try { & $Action }
    catch { $thrown = $true }
    Assert-True $thrown $Message
}

function Get-LiteralCount {
    param([string]$Content, [string]$Value)
    ([regex]::Matches($Content, [regex]::Escape($Value))).Count
}

$rawMainBoundary = 'async pushUpdate(t){if(!Object.hasOwn(UGe,t.topicName))throw new Error(`Invalid topic: ${t.topicName}`);const r=t.appliedUpdate;'
$rawMain = @(
    $rawMainBoundary
    'y={host:"127.0.0.1",resource:"",port:f.httpsPort,csrfToken:a,homeDir:sUs()};b.some(v=>v.port===f.httpsPort&&v.csrfToken===a)'
    'await this.a.initialize(f.httpsPort,a)'
) -join '|'
$stableMain = ConvertTo-StableMainContent -Content $rawMain

$qbAnchor = 'qb(e){if(e.choice.case!=="model")return;const i=Jku(e.choice.value);this.db.pushUpdate(i)}'
$dbAnchor = 'async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}'
$modelEncoder = 'function mUc(t){let e=Hi(GMt);return t?.modelAlias?e.choice={case:"alias",value:t.modelAlias}:t?.value&&(e.choice={case:"model",value:t.value}),e}'
$requestedModel = 'requestedModel:this.m,customModelInfoOverride:this.n'
$rawWorkbench = @(
    'get baseUrl(){return`https://127.0.0.1:${this.port}`}'
    $qbAnchor
    $dbAnchor
    $modelEncoder
    $requestedModel
) -join '|'
$stableWorkbench = ConvertTo-StableWorkbenchContent -Content $rawWorkbench -Adapter 'legacy-http-v1'

$geminiMain = ConvertTo-Gemini36MainContent -Content $stableMain
$geminiWorkbench = ConvertTo-Gemini36WorkbenchContent -Content $stableWorkbench
$bridgeDeclaration = 'const _agCompatibilityMode="gemini36-v1",_agGemini36Ids=new Set([1264,1265]),_agGemini36PreferenceKey="antigravity.compat.gemini36.preference.v1";'
$legacyAllowlist = '["Gemini 3.5 Flash (High)","Gemini 3.5 Flash (Medium)","Gemini 3.5 Flash (Low)","Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.6 Flash (High)","Gemini 3.6 Flash (Medium)","Gemini 3.6 Flash (Low)"]'

Assert-Equal 1 (Get-LiteralCount $geminiMain '_agCompatibilityMode="gemini36-v1"') 'main 兼容标记必须唯一'
foreach ($label in @('Gemini 3.6 Flash (High)', 'Gemini 3.6 Flash (Medium)')) {
    Assert-True ($geminiMain.Contains($label)) "兼容名单必须包含 $label"
}
Assert-True (-not $geminiMain.Contains('Gemini 3.5 Flash')) '兼容名单必须隐藏 Gemini 3.5'
Assert-True (-not $geminiMain.Contains('Gemini 3.6 Flash (Low)')) '兼容名单必须隐藏 Gemini 3.6 Low'
Assert-True (-not $geminiMain.Contains('Gemini 3.1')) '兼容名单仍须排除 Gemini 3.1'
Assert-True (-not $geminiMain.Contains('GPT')) '兼容名单仍须排除 GPT'
Assert-True (Test-Gemini36MainContent -Content $geminiMain) 'Gemini 3.6 main 结构检查应通过'

Assert-Equal 1 (Get-LiteralCount $geminiWorkbench $bridgeDeclaration) '工作台兼容助手声明必须唯一'
Assert-True ($geminiWorkbench.Contains('try{localStorage.setItem(_agGemini36PreferenceKey,String(e))}catch{}')) '本地偏好写入必须 try/catch'
Assert-True ($geminiWorkbench.Contains('try{localStorage.removeItem(_agGemini36PreferenceKey)}catch{}')) '本地偏好清理必须 try/catch'
Assert-True ($geminiWorkbench.Contains('Number.isInteger(e)&&_agGemini36Ids.has(e)?e:void 0')) '本地偏好只接受合法整数 ID'
Assert-True ($geminiWorkbench.Contains('if(_agGemini36Ids.has(i)){_agWriteGemini36(i);return}_agClearGemini36();const n=Jku(i);this.db.pushUpdate(n)')) '只有 3.6 ID 跳过 USS，普通模型仍须写入 USS'
Assert-True ($geminiWorkbench.Contains('s=_agReadGemini36()??Hku(n)')) '恢复时必须优先合法本地 3.6 ID'
Assert-True ($geminiWorkbench.Contains($modelEncoder)) 'mUc 真实 ID 编码链不得修改'
Assert-True ($geminiWorkbench.Contains($requestedModel)) 'requestedModel 真实 ID 请求链不得修改'
Assert-True (Test-Gemini36WorkbenchContent -Content $geminiWorkbench) 'Gemini 3.6 workbench 结构检查应通过'

Assert-Equal $geminiMain (ConvertTo-Gemini36MainContent -Content $geminiMain) 'Gemini 3.6 main 转换必须幂等'
Assert-Equal $geminiWorkbench (ConvertTo-Gemini36WorkbenchContent -Content $geminiWorkbench) 'Gemini 3.6 workbench 转换必须幂等'
Assert-Equal $stableMain (ConvertTo-StableMainContent -Content $geminiMain) 'Gemini 3.6 main 必须精确回退 Stable'
Assert-Equal $stableWorkbench (ConvertTo-StableWorkbenchContent -Content $geminiWorkbench -Adapter 'legacy-http-v1') 'Gemini 3.6 workbench 必须精确回退 Stable'
Assert-Equal 'Gemini36' (Get-InstalledCompatibilityMode -MainContent $geminiMain -WorkbenchContent $geminiWorkbench) '兼容模式识别'
Assert-Equal 'Stable' (Get-InstalledCompatibilityMode -MainContent $stableMain -WorkbenchContent $stableWorkbench) '稳定模式识别'
$transportOnlyStableWorkbench = 'get baseUrl(){return`http://127.0.0.1:${this.port}`}'
Assert-Equal 'Stable' (Get-InstalledCompatibilityMode -MainContent $stableMain -WorkbenchContent $transportOnlyStableWorkbench) 'Stable 模式识别必须按适配器契约而非 Gemini 锚点'

$legacyGeminiMain = $geminiMain.Replace(
    '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.6 Flash (High)","Gemini 3.6 Flash (Medium)"]',
    $legacyAllowlist,
    [StringComparison]::Ordinal)
$legacyGeminiWorkbench = $geminiWorkbench.Replace(
    '_agGemini36Ids=new Set([1264,1265])',
    '_agGemini36Ids=new Set([1264,1265,1266])',
    [StringComparison]::Ordinal)
$stableAllowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]'
$legacyStableAllowlist = '["Gemini 3.5 Flash (High)","Gemini 3.5 Flash (Medium)","Gemini 3.5 Flash (Low)","Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]'
$legacyStableMain = $stableMain.Replace($stableAllowlist, $legacyStableAllowlist, [StringComparison]::Ordinal)

Assert-Equal 'Stable' (Get-InstalledCompatibilityMode -MainContent $legacyStableMain -WorkbenchContent $stableWorkbench) '旧 Stable 模式必须可识别以触发名单升级'
Assert-Equal $stableMain (ConvertTo-StableMainContent -Content $legacyStableMain) '旧 Stable main 必须可直接升级为仅 Claude 名单'
Assert-Equal 'Gemini36' (Get-InstalledCompatibilityMode -MainContent $legacyGeminiMain -WorkbenchContent $legacyGeminiWorkbench) '旧 Gemini36 模式必须可识别以触发升级'
Assert-Equal $geminiMain (ConvertTo-Gemini36MainContent -Content $legacyGeminiMain) '旧 Gemini36 main 必须可直接升级到新名单'
Assert-Equal $geminiWorkbench (ConvertTo-Gemini36WorkbenchContent -Content $legacyGeminiWorkbench) '旧 Gemini36 workbench 必须可直接升级到新 ID 桥'
Assert-Equal $stableMain (ConvertTo-StableMainContent -Content $legacyGeminiMain) '旧 Gemini36 main 必须可迁移回 Stable'
Assert-Equal $stableWorkbench (ConvertTo-StableWorkbenchContent -Content $legacyGeminiWorkbench -Adapter 'legacy-http-v1') '旧 Gemini36 workbench 必须可迁移回 Stable'
Assert-Equal $geminiMain (ConvertTo-Gemini36MainContent -Content (ConvertTo-StableMainContent -Content $legacyGeminiMain)) '旧 Gemini36 main 必须可升级到新名单'
Assert-Equal $geminiWorkbench (ConvertTo-Gemini36WorkbenchContent -Content (ConvertTo-StableWorkbenchContent -Content $legacyGeminiWorkbench -Adapter 'legacy-http-v1')) '旧 Gemini36 workbench 必须可升级到新 ID 桥'

$installRoot = Join-Path ([IO.Path]::GetTempPath()) ("Antigravity-Gemini36-$([guid]::NewGuid().ToString('N'))")
try {
    $mainPath = Join-Path $installRoot 'resources\app\out\main.js'
    $workbenchPath = Join-Path $installRoot 'resources\app\out\vs\workbench\workbench.desktop.main.js'
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($mainPath)) | Out-Null
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($workbenchPath)) | Out-Null
    [IO.File]::WriteAllText($mainPath, $geminiMain)
    [IO.File]::WriteAllText($workbenchPath, $geminiWorkbench)
    Assert-Equal 'Gemini36' (Get-InstalledCompatibilityMode -InstallRoot $installRoot) '安装目录模式识别'
}
finally {
    Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Assert-Throws { ConvertTo-Gemini36MainContent -Content ($stableMain.Replace($stableAllowlist, '[]')) | Out-Null } 'main 缺失名单锚点必须拒绝'
Assert-Throws { ConvertTo-Gemini36MainContent -Content ($stableMain + $stableAllowlist) | Out-Null } 'main 重复名单锚点必须拒绝'
Assert-Throws { ConvertTo-Gemini36MainContent -Content ('const _agCompatibilityMode="gemini36-v2";' + $stableMain) | Out-Null } 'main 未知兼容标记必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench.Replace($qbAnchor, '')) | Out-Null } 'workbench 缺失 qb 锚点必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench + $qbAnchor) | Out-Null } 'workbench 重复 qb 锚点必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench.Replace($dbAnchor, '')) | Out-Null } 'workbench 缺失 Db 锚点必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench + $dbAnchor) | Out-Null } 'workbench 重复 Db 锚点必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench.Replace($modelEncoder, '')) | Out-Null } 'workbench 缺失真实 ID 编码链必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench + $modelEncoder) | Out-Null } 'workbench 重复真实 ID 编码链必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench.Replace($requestedModel, '')) | Out-Null } 'workbench 缺失 requestedModel 请求链必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ($stableWorkbench + $requestedModel) | Out-Null } 'workbench 重复 requestedModel 请求链必须拒绝'
Assert-Throws { ConvertTo-Gemini36WorkbenchContent -Content ('const _agCompatibilityMode="gemini36-v2";' + $stableWorkbench) | Out-Null } 'workbench 未知兼容标记必须拒绝'
Assert-Throws { ConvertTo-StableWorkbenchContent -Content ($geminiWorkbench.Replace('gemini36-v1', 'gemini36-v2')) -Adapter 'legacy-http-v1' | Out-Null } '未知兼容标记必须 fail-closed'
Assert-Throws { Get-InstalledCompatibilityMode -MainContent $geminiMain -WorkbenchContent $stableWorkbench | Out-Null } 'main/workbench 混合模式必须拒绝'
Assert-Throws { Get-InstalledCompatibilityMode -MainContent $legacyGeminiMain -WorkbenchContent $geminiWorkbench | Out-Null } '新旧 Gemini36 混合结构必须拒绝'
Assert-True (-not (Test-Gemini36MainContent -Content ($geminiMain + $legacyAllowlist))) '当前 Gemini36 main 混入旧名单必须拒绝'
Assert-True (-not (& $module { param($content) Test-LegacyGemini36MainContent -Content $content } ($legacyGeminiMain + $stableAllowlist))) '旧 Gemini36 main 混入当前名单必须拒绝'
Assert-True (-not (Test-StableMainContent -Content ($stableMain + $legacyStableAllowlist))) '当前 Stable main 混入旧名单必须拒绝'

$restartSafeExtension = 'a.LanguageServerClient.initialize(),await a.LanguageServerClient.getInstance().initAsync(),e.subscriptions.push(a.LanguageServerClient.getInstance()),b.UserStatusUpdater.getInstance().restartUpdateLoop(),i.end(),i=c.JetskiTrace.task("extension activate: unleash init")'
Assert-Throws {
    & $module {
        param($main, $workbench, $extension)
        Get-CompatibilityCandidate -MainContent $main -WorkbenchContent $workbench -ExtensionContent $extension -Mode Gemini36 | Out-Null
    } $legacyGeminiMain $geminiWorkbench $restartSafeExtension
} '实际 Candidate 路径必须拒绝新旧 Gemini36 混合结构'

Write-Output 'PASS: Gemini 3.6 catalog, preference bridge, reversibility, idempotency, and fail-closed anchors'

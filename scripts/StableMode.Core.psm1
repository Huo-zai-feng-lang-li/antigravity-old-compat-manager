Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RawMainSha256 = 'C98CFE9D4256FDA7E9F30603CDCDDF45E206A4DC3181784C1508E218B6562D65'
$script:StableMainSha256 = '41BCE5A0E3A2B7F6F3AA7110B69C3F2C860DF685293948DF23FCDCB7B9AFF1DD'
$script:LegacyStableMainSha256 = '710FAB9A65D38BAD5923DCF1C99E0D9EDF017B4C3E86985A8A34533D9AA79C1A'
$script:RawWorkbenchSha256 = 'EA1037E96BA164009C8965FEB83D9D0D5FD45B39FA83C592AB57302489C590A5'
$script:StableWorkbenchSha256 = '9207A2E23A78E4A0CACF86E2C4B63EBD401809B16275AF9D560731962578CEE1'
$script:StableIdeVersion = '2.5.5'
$script:StableDate = '2026-08-13T08:28:19.366Z'
$script:StableAllowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]'
$script:LegacyStableAllowlist = '["Gemini 3.5 Flash (High)","Gemini 3.5 Flash (Medium)","Gemini 3.5 Flash (Low)","Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]'
$script:Gemini36Allowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.6 Flash (High)","Gemini 3.6 Flash (Medium)"]'
$script:LegacyGemini36Allowlist = '["Gemini 3.5 Flash (High)","Gemini 3.5 Flash (Medium)","Gemini 3.5 Flash (Low)","Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.6 Flash (High)","Gemini 3.6 Flash (Medium)","Gemini 3.6 Flash (Low)"]'
$script:Gemini36MainMarker = 'const _agCompatibilityMode="gemini36-v1";'
$script:Gemini36WorkbenchPrefix = 'const _agCompatibilityMode="gemini36-v1",_agGemini36Ids=new Set([1264,1265]),_agGemini36PreferenceKey="antigravity.compat.gemini36.preference.v1";function _agWriteGemini36(e){try{localStorage.setItem(_agGemini36PreferenceKey,String(e))}catch{}}function _agClearGemini36(){try{localStorage.removeItem(_agGemini36PreferenceKey)}catch{}}function _agReadGemini36(){try{const e=Number(localStorage.getItem(_agGemini36PreferenceKey));return Number.isInteger(e)&&_agGemini36Ids.has(e)?e:void 0}catch{return void 0}}'
$script:LegacyGemini36WorkbenchPrefix = 'const _agCompatibilityMode="gemini36-v1",_agGemini36Ids=new Set([1264,1265,1266]),_agGemini36PreferenceKey="antigravity.compat.gemini36.preference.v1";function _agWriteGemini36(e){try{localStorage.setItem(_agGemini36PreferenceKey,String(e))}catch{}}function _agClearGemini36(){try{localStorage.removeItem(_agGemini36PreferenceKey)}catch{}}function _agReadGemini36(){try{const e=Number(localStorage.getItem(_agGemini36PreferenceKey));return Number.isInteger(e)&&_agGemini36Ids.has(e)?e:void 0}catch{return void 0}}'
$script:Gemini36QbAnchor = 'qb(e){if(e.choice.case!=="model")return;const i=Jku(e.choice.value);this.db.pushUpdate(i)}'
$script:Gemini36QbReplacement = 'qb(e){if(e.choice.case!=="model")return;const i=e.choice.value;if(_agGemini36Ids.has(i)){_agWriteGemini36(i);return}_agClearGemini36();const n=Jku(i);this.db.pushUpdate(n)}'
$script:Gemini36DbAnchor = 'async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}'
$script:Gemini36DbReplacement = 'async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=_agReadGemini36()??Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}'
$script:Gemini36ModelEncoderAnchor = 'function mUc(t){let e=Hi(GMt);return t?.modelAlias?e.choice={case:"alias",value:t.modelAlias}:t?.value&&(e.choice={case:"model",value:t.value}),e}'
$script:Gemini36RequestedModelAnchor = 'requestedModel:this.m,customModelInfoOverride:this.n'
$script:Gemini37Allowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.8 Flash (High)"]'
$script:PreviousGemini37Allowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.7 Flash (High)","Gemini 3.8 Flash (High)"]'
$script:OlderGemini37Allowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.6 Flash (High)","Gemini 3.6 Flash (Medium)","Gemini 3.7 Flash","Gemini 3.7 Flash (High)","Gemini 3.7 Flash (Medium)","Gemini 3.8 Flash","Gemini 3.8 Flash (High)","Gemini 3.8 Flash (Medium)"]'
$script:OldestGemini37Allowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Gemini 3.6 Flash (High)","Gemini 3.6 Flash (Medium)","Gemini 3.7 Flash","Gemini 3.7 Flash (High)","Gemini 3.7 Flash (Medium)"]'
$script:LegacyGemini37Allowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)","Claude Sonnet 4.6 (thinking)","Claude Opus 4.6 (thinking)","Gemini 3.7 Flash","Gemini 3.7 Flash (High)","Gemini 3.7 Flash (Medium)"]'
$script:Gemini37MainMarker = 'const _agCompatibilityMode="gemini37-v1";'
$script:Gemini37WorkbenchPrefix = 'const _agCompatibilityMode="gemini37-combined-v2",_agGemini36Ids=new Set([1264,1265]),_agGemini36PreferenceKey="antigravity.compat.gemini36.preference.v1",_agGemini37PreferenceKey="antigravity.compat.gemini37.preference.v1";function _agWriteGemini36(e){try{localStorage.setItem(_agGemini36PreferenceKey,String(e))}catch{}}function _agClearGemini36(){try{localStorage.removeItem(_agGemini36PreferenceKey)}catch{}}function _agReadGemini36(){try{const e=Number(localStorage.getItem(_agGemini36PreferenceKey));return Number.isInteger(e)&&_agGemini36Ids.has(e)?e:void 0}catch{return void 0}}function _agWriteGemini37(){try{localStorage.setItem(_agGemini37PreferenceKey,"8")}catch{}}function _agClearGemini37(){try{localStorage.removeItem(_agGemini37PreferenceKey)}catch{}}function _agReadGemini37(){try{return localStorage.getItem(_agGemini37PreferenceKey)==="8"}catch{return false}}'
$script:PreviousGemini37WorkbenchPrefix = 'const _agCompatibilityMode="gemini37-combined-v2",_agGemini36Ids=new Set([1264,1265]),_agGemini36PreferenceKey="antigravity.compat.gemini36.preference.v1";function _agWriteGemini36(e){try{localStorage.setItem(_agGemini36PreferenceKey,String(e))}catch{}}function _agClearGemini36(){try{localStorage.removeItem(_agGemini36PreferenceKey)}catch{}}function _agReadGemini36(){try{const e=Number(localStorage.getItem(_agGemini36PreferenceKey));return Number.isInteger(e)&&_agGemini36Ids.has(e)?e:void 0}catch{return void 0}}'
$script:Gemini37QbReplacement = 'qb(e){if(e.choice.case==="alias"&&e.choice.value===8){_agWriteGemini37();_agClearGemini36();return}if(e.choice.case!=="model")return;const i=e.choice.value;if(_agGemini36Ids.has(i)){_agWriteGemini36(i);_agClearGemini37();return}_agClearGemini36();_agClearGemini37();const n=Jku(i);this.db.pushUpdate(n)}'
$script:Gemini37DbReplacement = 'async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=_agReadGemini36()??Hku(n),r=_agReadGemini37()?{case:"alias",value:8}:{case:"model",value:s};this.setSelectedModel(hs(RGl,{choice:r}),void 0,!1)}))}'
$script:LegacyGemini37WorkbenchPrefix = 'const _agCompatibilityMode="gemini37-v1",_agGemini37Ids=new Set,_agGemini37PreferenceKey="antigravity.compat.gemini37.preference.v1";function _agRememberGemini37(e,t){if(typeof e==="string"&&/^Gemini 3\.7(?: |$)/.test(e)&&!/\(Low\)$/.test(e)&&Number.isInteger(t))_agGemini37Ids.add(t)}function _agWriteGemini37(e){try{localStorage.setItem(_agGemini37PreferenceKey,String(e))}catch{}}function _agClearGemini37(){try{localStorage.removeItem(_agGemini37PreferenceKey)}catch{}}function _agReadGemini37(){try{const e=Number(localStorage.getItem(_agGemini37PreferenceKey));return Number.isInteger(e)&&_agGemini37Ids.has(e)?e:void 0}catch{return void 0}}'
$script:OlderGemini37WorkbenchPrefix = $script:LegacyGemini37WorkbenchPrefix.Replace(
    'Number.isInteger(e)&&_agGemini37Ids.has(e)?e:void 0',
    'Number.isInteger(e)?e:void 0',
    [StringComparison]::Ordinal
)
$script:LegacyGemini37QbReplacement = 'qb(e){if(e.choice.case!=="model")return;const i=e.choice.value;if(_agGemini37Ids.has(i)){_agWriteGemini37(i);return}_agClearGemini37();const n=Jku(i);this.db.pushUpdate(n)}'
$script:LegacyGemini37DbReplacement = 'async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=_agReadGemini37()??Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}'
$script:LegacyGemini37ModelOptionAnchor = 'Qun=t=>{if(!t.modelOrAlias)return null;let e=t.modelOrAlias.choice.case==="model"?t.modelOrAlias.choice.value:oz.UNSPECIFIED,i=t.modelOrAlias.choice.case==="alias"?t.modelOrAlias.choice.value:void 0;return{label:t.label,value:e'
$script:LegacyGemini37ModelOptionReplacement = 'Qun=t=>{if(!t.modelOrAlias)return null;let e=t.modelOrAlias.choice.case==="model"?t.modelOrAlias.choice.value:oz.UNSPECIFIED,i=t.modelOrAlias.choice.case==="alias"?t.modelOrAlias.choice.value:void 0;_agRememberGemini37(t.label,e);return{label:t.label,value:e'
$script:AuthEarlyPattern = '(?<prefix>\b[A-Za-z_$][A-Za-z0-9_$]*\.MetadataProvider\.initialize\(e\),i\.end\(\),)(?<updater>[A-Za-z_$][A-Za-z0-9_$]*\.UserStatusUpdater\.getInstance\(\)\.restartUpdateLoop\(\),)(?<suffix>i=[A-Za-z_$][A-Za-z0-9_$]*\.JetskiTrace\.task\("extension activate: sentry init"\))'
$script:AuthReadyPattern = '(?<prefix>(?<ls>[A-Za-z_$][A-Za-z0-9_$]*)\.LanguageServerClient\.initialize\(\),await \k<ls>\.LanguageServerClient\.getInstance\(\)\.initAsync\(\),e\.subscriptions\.push\(\k<ls>\.LanguageServerClient\.getInstance\(\)\),)(?<suffix>i\.end\(\),i=[A-Za-z_$][A-Za-z0-9_$]*\.JetskiTrace\.task\("extension activate: unleash init"\))'
$script:AuthSafePattern = '(?<ls>[A-Za-z_$][A-Za-z0-9_$]*)\.LanguageServerClient\.initialize\(\),await \k<ls>\.LanguageServerClient\.getInstance\(\)\.initAsync\(\),e\.subscriptions\.push\(\k<ls>\.LanguageServerClient\.getInstance\(\)\),(?<updater>[A-Za-z_$][A-Za-z0-9_$]*\.UserStatusUpdater\.getInstance\(\)\.restartUpdateLoop\(\),)i\.end\(\),i=[A-Za-z_$][A-Za-z0-9_$]*\.JetskiTrace\.task\("extension activate: unleash init"\)'
$script:OneLsSpawnAnchor = 'const n=XBa(),a=qZr(this.b,n,this.m,this.n);this.f.info(`[LS Main] Args: ${a.join(" ")}`);'
$script:OneLsBridgeHelper = 'const _agOneLSAgentProxy=async(e,t)=>{try{const r=await import(new URL("../dao-one-ls-agent-pro.cjs",import.meta.url)),n=await(r.default??r).waitForAgentProxy({timeoutMs:1e4}),s=t.indexOf("--cloud_code_endpoint");if(typeof n==="string"&&/^http:\/\/127\.0\.0\.1:\d+$/.test(n)&&s>=0&&s===t.lastIndexOf("--cloud_code_endpoint")&&s+1<t.length)return t[s+1]=n,e.info("[LS Main] Agent Pro bridge ready"),!0;return e.info("[LS Main] Agent Pro bridge fallback"),!1}catch(t){return e.warn("[LS Main] Agent Pro bridge fallback: "+(t?.message??"bridge unavailable")),!1}};'
$script:OneLsBridgedSpawnAnchor = 'const n=XBa(),a=qZr(this.b,n,this.m,this.n);await _agOneLSAgentProxy(this.f,a);this.f.info(`[LS Main] Args: ${a.join(" ")}`);'
$script:OneLsBridgeSourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'runtime\OneLSAgentProxyBridge.cjs'
$script:Gemini37AgentProHelperSourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'runtime\Gemini37AgentProxyCompat.cjs'
$script:Gemini37AgentProHelperName = '_ag-gemini37-compat.cjs'
$script:Gemini37AgentProRequire = 'const _agGemini37Compat = require("./_ag-gemini37-compat.cjs");'
$script:Gemini37AgentProHook = @'
    if (kind === "GEMINI_REST_CHAT") {
      const _agGemini37Body = _agGemini37Compat.rewriteRequestBody(_eaBody);
      if (_agGemini37Body !== _eaBody) {
        _eaDiag(`#${rid} GEMINI37-MODEL-REWRITE: gemini-2.5-pro -> gemini-3.8-flash-high`);
        _eaBody = _agGemini37Body;
      }
    }
'@

function Find-AntigravityInstallRoots {
    $results = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $candidates = [Collections.Generic.List[string]]::new()

    foreach ($known in @('D:\Antigravity IDE', 'D:\Antigravity')) { $candidates.Add($known) }
    $containers = @(
        $env:LOCALAPPDATA,
        (Join-Path $env:LOCALAPPDATA 'Programs'),
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        [Environment]::GetFolderPath('Desktop')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container) }

    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        if (Test-Path -LiteralPath $drive.Root -PathType Container) { $containers += $drive.Root }
    }
    foreach ($container in $containers | Select-Object -Unique) {
        foreach ($directory in Get-ChildItem -LiteralPath $container -Directory -ErrorAction SilentlyContinue) {
            if ($directory.Name -like '*Antigravity*') { $candidates.Add($directory.FullName) }
        }
    }

    foreach ($candidate in $candidates) {
        $root = try { [IO.Path]::GetFullPath($candidate).TrimEnd('\', '/') } catch { continue }
        if (-not $seen.Add($root)) { continue }
        $required = @(
            (Join-Path $root 'Antigravity.exe'),
            (Join-Path $root 'resources\app\out\main.js'),
            (Join-Path $root 'resources\app\out\vs\workbench\workbench.desktop.main.js'),
            (Join-Path $root 'resources\app\extensions\antigravity\dist\extension.js')
        )
        if (@($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }).Count -eq 0) {
            $results.Add($root)
        }
    }
    $results
}

function Find-AgentProSourcePath {
    param([string]$ExplicitPath)

    $requested = if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $ExplicitPath
    } else {
        $env:ANTIGRAVITY_AGENT_PRO_SOURCE
    }
    if (-not [string]::IsNullOrWhiteSpace($requested)) {
        $resolved = [IO.Path]::GetFullPath($requested)
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { throw "Agent Pro source.js 不存在：$resolved" }
        return $resolved
    }

    $extensionsRoot = Join-Path $env:USERPROFILE '.antigravity\extensions'
    if (-not (Test-Path -LiteralPath $extensionsRoot -PathType Container)) { return $null }
    $prefix = 'dao-agi.dao-proxy-pro-'
    $candidates = foreach ($directory in Get-ChildItem -LiteralPath $extensionsRoot -Directory -Filter "$prefix*") {
        $source = Join-Path $directory.FullName 'vendor\bundled-origin\source.js'
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { continue }
        $versionText = $directory.Name.Substring($prefix.Length)
        $version = try { [version]$versionText } catch { [version]'0.0' }
        [pscustomobject]@{ Source = $source; Version = $version; Updated = $directory.LastWriteTimeUtc }
    }
    $selected = @($candidates | Sort-Object Version, Updated -Descending | Select-Object -First 1 -ExpandProperty Source)
    if ($selected.Count -eq 0) { return $null }
    $selected[0]
}

function Get-InstallFiles {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [string]$AgentProSourcePath
    )

    $root = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
    $agentProSource = if ([string]::IsNullOrWhiteSpace($AgentProSourcePath)) {
        $null
    } else {
        [IO.Path]::GetFullPath($AgentProSourcePath)
    }
    [pscustomobject]@{
        Root = $root
        Exe = Join-Path $root 'Antigravity.exe'
        Main = Join-Path $root 'resources\app\out\main.js'
        Workbench = Join-Path $root 'resources\app\out\vs\workbench\workbench.desktop.main.js'
        Extension = Join-Path $root 'resources\app\extensions\antigravity\dist\extension.js'
        Product = Join-Path $root 'resources\app\product.json'
        Bridge = Join-Path $root 'resources\app\dao-one-ls-agent-pro.cjs'
        AgentProSource = $agentProSource
        AgentProCompat = if ($null -eq $agentProSource) { $null } else { Join-Path (Split-Path $agentProSource -Parent) $script:Gemini37AgentProHelperName }
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
}

function Get-StringSha256 {
    param([Parameter(Mandatory)][string]$Content)
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Content)
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
}

function Get-ExactCount {
    param([string]$Content, [string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { throw '匹配值不能为空。' }
    $count = 0
    $offset = 0
    while ($offset -lt $Content.Length) {
        $index = $Content.IndexOf($Value, $offset, [StringComparison]::Ordinal)
        if ($index -lt 0) { break }
        $count++
        $offset = $index + $Value.Length
    }
    $count
}

function Replace-ExactOnce {
    param([string]$Content, [string]$Before, [string]$After, [string]$Name)
    $count = Get-ExactCount -Content $Content -Value $Before
    if ($count -ne 1) { throw "$Name 锚点期望 1 次，实际 $count 次。" }
    $Content.Replace($Before, $After, [StringComparison]::Ordinal)
}

function Test-Gemini37AgentProSourceContent {
    param([Parameter(Mandatory)][string]$Content)

    $normalizedContent = $Content.Replace("`r`n", "`n")
    $normalizedHook = $script:Gemini37AgentProHook.TrimEnd("`r", "`n").Replace("`r`n", "`n")
    (Get-ExactCount -Content $Content -Value $script:Gemini37AgentProRequire) -eq 1 -and
        (Get-ExactCount -Content $normalizedContent -Value $normalizedHook) -eq 1 -and
        (Get-ExactCount -Content $Content -Value 'const net = require("net");') -eq 1 -and
        (Get-ExactCount -Content $Content -Value '    _eaHotReload();') -eq 1
}

function ConvertTo-Gemini37AgentProSourceContent {
    param([Parameter(Mandatory)][string]$Content)

    if (Test-Gemini37AgentProSourceContent -Content $Content) { return $Content }

    # 如果存在旧版本的 3.7 路由日志特征，先无损平滑回退，再打入 3.8 路由
    $legacy37Hook = @'
    if (kind === "GEMINI_REST_CHAT") {
      const _agGemini37Body = _agGemini37Compat.rewriteRequestBody(_eaBody);
      if (_agGemini37Body !== _eaBody) {
        _eaDiag(`#${rid} GEMINI37-MODEL-REWRITE: gemini-2.5-pro -> gemini-3.7-flash-high`);
        _eaBody = _agGemini37Body;
      }
    }
'@.TrimEnd("`r", "`n")

    $workingContent = $Content
    $normalizedWorking = $workingContent.Replace("`r`n", "`n")
    $normalizedLegacyHook = $legacy37Hook.Replace("`r`n", "`n")
    if ($normalizedWorking.Contains($normalizedLegacyHook)) {
        $workingContent = ConvertTo-StableAgentProSourceContent -Content $workingContent
    }

    if ($workingContent.Contains($script:Gemini37AgentProHelperName) -or $workingContent.Contains('GEMINI37-MODEL-REWRITE')) {
        throw 'Agent Pro source.js 含不完整的 Gemini 路由补丁，拒绝覆盖。'
    }
    $newLine = [Environment]::NewLine
    $result = Replace-ExactOnce $workingContent 'const net = require("net");' ($script:Gemini37AgentProRequire + $newLine + 'const net = require("net");') 'Agent Pro helper 引用'
    $hook = $script:Gemini37AgentProHook.TrimEnd("`r", "`n")
    $result = Replace-ExactOnce $result '    _eaHotReload();' ($hook + $newLine + '    _eaHotReload();') 'Gemini 3.8 请求模型改写'
    if (-not (Test-Gemini37AgentProSourceContent -Content $result)) { throw 'Agent Pro Gemini 3.8 路由补丁后结构校验失败。' }
    $result
}

function ConvertTo-StableAgentProSourceContent {
    param([Parameter(Mandatory)][string]$Content)

    $hasPatch = $Content.Contains($script:Gemini37AgentProHelperName) -or $Content.Contains('GEMINI37-MODEL-REWRITE')
    if (-not $hasPatch) { return $Content }

    $legacy37Hook = @'
    if (kind === "GEMINI_REST_CHAT") {
      const _agGemini37Body = _agGemini37Compat.rewriteRequestBody(_eaBody);
      if (_agGemini37Body !== _eaBody) {
        _eaDiag(`#${rid} GEMINI37-MODEL-REWRITE: gemini-2.5-pro -> gemini-3.7-flash-high`);
        _eaBody = _agGemini37Body;
      }
    }
'@.TrimEnd("`r", "`n")

    $currentHook = $script:Gemini37AgentProHook.TrimEnd("`r", "`n")

    $newLine = if ($Content.Contains($script:Gemini37AgentProRequire + "`r`n" + 'const net = require("net");')) { "`r`n" } else { "`n" }
    
    $stable = $Content
    if ($stable.Contains($script:Gemini37AgentProRequire + $newLine + 'const net = require("net");')) {
        $stable = Replace-ExactOnce $stable ($script:Gemini37AgentProRequire + $newLine + 'const net = require("net");') 'const net = require("net");' 'Agent Pro helper 引用回退'
    }

    # 尝试匹配当前 3.8 hook 或旧 3.7 hook
    $matchedHook = $null
    if ($stable.Contains($currentHook)) { $matchedHook = $currentHook }
    elseif ($stable.Contains($currentHook.Replace("`r`n", "`n"))) { $matchedHook = $currentHook.Replace("`r`n", "`n") }
    elseif ($stable.Contains($legacy37Hook)) { $matchedHook = $legacy37Hook }
    elseif ($stable.Contains($legacy37Hook.Replace("`r`n", "`n"))) { $matchedHook = $legacy37Hook.Replace("`r`n", "`n") }

    if ($null -ne $matchedHook) {
        $hookWithNewline = if ($stable.Contains($matchedHook + "`r`n" + '    _eaHotReload();')) { $matchedHook + "`r`n" + '    _eaHotReload();' } else { $matchedHook + "`n" + '    _eaHotReload();' }
        $stable = Replace-ExactOnce $stable $hookWithNewline '    _eaHotReload();' 'Gemini 请求模型改写回退'
    }

    if ($stable.Contains($script:Gemini37AgentProHelperName) -or $stable.Contains('GEMINI37-MODEL-REWRITE')) {
        throw 'Agent Pro source.js 的 Gemini 路由补丁结构不完整，拒绝回退。'
    }
    $stable
}

function Test-StableCatalogFilterContent {
    param([Parameter(Mandatory)][string]$Content)

    $required = @(
        "const _agStableLabels=new Set($script:StableAllowlist)",
        'function _agFilterStatus(e){const t=e?.cascadeModelConfigData;',
        'function _agFilterEncoded(e){try{return La(oS,_agFilterStatus(fi(e,oS)))}catch{return La(oS,ct(oS))}}',
        'function n9a(e,t,r,n){return _agFilterStatus(ct(oS,',
        'return a.data?.[WP]?.value&&(a.data[WP].value=_agFilterEncoded(a.data[WP].value)),a}',
        't.data?.[WP]?.value&&(t.data[WP].value=_agFilterEncoded(t.data[WP].value));const n=La(ea,t)'
    )
    foreach ($anchor in $required) {
        if ((Get-ExactCount -Content $Content -Value $anchor) -ne 1) { return $false }
    }
    $true
}

function Ensure-StableCatalogDefaultSafety {
    param([Parameter(Mandatory)][string]$Content)

    $guard = 'const _agStableStartupLabels=new Set(["Claude Opus 4.6 (Thinking)","Claude Sonnet 4.6 (Thinking)"]);'
    $safeTail = 'const n=new Set(t.clientModelConfigs.map(a=>a.modelOrAlias?.choice).filter(a=>a).map(a=>`${a.case}:${a.value}`)),a=t.defaultOverrideModelConfig?.modelOrAlias?.choice;return a&&!n.has(`${a.case}:${a.value}`)&&(t.defaultOverrideModelConfig=void 0),e}'
    if ((Get-ExactCount -Content $Content -Value $guard) -eq 0 -and
        (Get-ExactCount -Content $Content -Value $safeTail) -eq 1) {
        return $Content
    }
    $result = $Content
    if ((Get-ExactCount -Content $result -Value $guard) -eq 1) {
        $result = Replace-ExactOnce -Content $result -Before $guard -After '' -Name '旧启动默认集合移除'
    }
    $oldTail = 'const n=new Set(t.clientModelConfigs.map(a=>a.modelOrAlias?.choice).filter(a=>a?.case==="model").map(a=>a.value)),a=t.defaultOverrideModelConfig?.modelOrAlias?.choice;return a?.case==="model"&&!n.has(a.value)&&(t.defaultOverrideModelConfig=void 0),e}'
    $guardTail = 'const n=new Set(t.clientModelConfigs.map(a=>a.modelOrAlias?.choice).filter(a=>a?.case==="model").map(a=>a.value)),a=t.defaultOverrideModelConfig?.modelOrAlias?.choice,i=t.clientModelConfigs.find(s=>_agStableStartupLabels.has(s?.label));return i&&(t.defaultOverrideModelConfig=i),a?.case==="model"&&!n.has(a.value)&&(t.defaultOverrideModelConfig=i??void 0),e}'
$geminiClearTail = 'const n=new Set(t.clientModelConfigs.map(a=>a.modelOrAlias?.choice).filter(a=>a?.case==="model").map(a=>a.value)),a=t.defaultOverrideModelConfig?.modelOrAlias?.choice,i=t.clientModelConfigs.find(s=>s?.label==="Gemini 3.7 Flash (High)");return !a&&i&&(t.defaultOverrideModelConfig=i),a?.case==="model"&&!n.has(a.value)&&(t.defaultOverrideModelConfig=i??void 0),e}'
    if ((Get-ExactCount -Content $result -Value $guardTail) -eq 1) {
        return Replace-ExactOnce -Content $result -Before $guardTail -After $safeTail -Name '旧启动默认逻辑迁移'
    }
    if ((Get-ExactCount -Content $result -Value $geminiClearTail) -eq 1) {
        return Replace-ExactOnce -Content $result -Before $geminiClearTail -After $safeTail -Name 'Gemini 3.7 alias 默认逻辑迁移'
    }
    Replace-ExactOnce -Content $result -Before $oldTail -After $safeTail -Name 'Gemini 3.7 默认覆盖隔离'
}

function Ensure-StableCatalogAliasCompatibility {
    param([Parameter(Mandatory)][string]$Content)

    $patches = @(
        [pscustomobject]@{
            Name = '重复模型 choice 去重迁移'
            Before = 't.clientModelConfigs=(t.clientModelConfigs??[]).filter(r=>_agStableLabels.has(r?.label)&&(!/^Gemini 3\.7(?: |$)/.test(r?.label??"")||r.modelOrAlias?.choice?.case!=="model"||r.modelOrAlias.choice.value!==0));'
            After = 'const _agSeenChoices=new Set;t.clientModelConfigs=(t.clientModelConfigs??[]).filter(r=>{if(!_agStableLabels.has(r?.label)||/^Gemini 3\.7(?: |$)/.test(r?.label??"")&&r.modelOrAlias?.choice?.case==="model"&&r.modelOrAlias.choice.value===0)return!1;const n=r.modelOrAlias?.choice,a=n&&`${n.case}:${n.value}`;return!!a&&!_agSeenChoices.has(a)&&(_agSeenChoices.add(a),!0)});'
        }
        [pscustomobject]@{
            Name = 'Gemini 3.7 失真缓存隔离'
            Before = 't.clientModelConfigs=(t.clientModelConfigs??[]).filter(r=>_agStableLabels.has(r?.label));'
            After = 'const _agSeenChoices=new Set;t.clientModelConfigs=(t.clientModelConfigs??[]).filter(r=>{if(!_agStableLabels.has(r?.label)||/^Gemini 3\.7(?: |$)/.test(r?.label??"")&&r.modelOrAlias?.choice?.case==="model"&&r.modelOrAlias.choice.value===0)return!1;const n=r.modelOrAlias?.choice,a=n&&`${n.case}:${n.value}`;return!!a&&!_agSeenChoices.has(a)&&(_agSeenChoices.add(a),!0)});'
        }
        [pscustomobject]@{
            Name = '错误字符串 alias 迁移'
            Before = 'modelOrAlias:ct(INe,{choice:t.model?{case:"model",value:t.model}:{case:"alias",value:e}})'
            After = 'modelOrAlias:ct(INe,{choice:t.model?{case:"model",value:t.model}:t.recommended?{case:"alias",value:8}:{case:"model",value:0}})'
        }
        [pscustomobject]@{
            Name = '推荐新模型 alias 映射'
            Before = 'modelOrAlias:ct(INe,{choice:{case:"model",value:t.model}})'
            After = 'modelOrAlias:ct(INe,{choice:t.model?{case:"model",value:t.model}:t.recommended?{case:"alias",value:8}:{case:"model",value:0}})'
        }
        [pscustomobject]@{
            Name = '错误默认字符串 alias 迁移'
            Before = 's=ct(pIt,{modelOrAlias:ct(INe,{choice:d.model?{case:"model",value:d.model}:{case:"alias",value:l}})})'
            After = 's=ct(pIt,{modelOrAlias:ct(INe,{choice:d.model?{case:"model",value:d.model}:d.recommended?{case:"alias",value:8}:{case:"model",value:0}})})'
        }
        [pscustomobject]@{
            Name = '默认推荐模型 alias 映射'
            Before = 's=ct(pIt,{modelOrAlias:ct(INe,{choice:{case:"model",value:d.model}})})'
            After = 's=ct(pIt,{modelOrAlias:ct(INe,{choice:d.model?{case:"model",value:d.model}:d.recommended?{case:"alias",value:8}:{case:"model",value:0}})})'
        }
    )
    $result = $Content
    foreach ($patch in $patches) {
        if ((Get-ExactCount -Content $result -Value $patch.After) -eq 1) { continue }
        if ((Get-ExactCount -Content $result -Value $patch.Before) -eq 0) { continue }
        $result = Replace-ExactOnce -Content $result -Before $patch.Before -After $patch.After -Name $patch.Name
    }
    $result
}

function Test-StableCatalogAliasCompatibility {
    param([Parameter(Mandatory)][string]$Content)

    $required = @(
        'const _agSeenChoices=new Set;t.clientModelConfigs=(t.clientModelConfigs??[]).filter(r=>{if(!_agStableLabels.has(r?.label)||/^Gemini 3\.7(?: |$)/.test(r?.label??"")&&r.modelOrAlias?.choice?.case==="model"&&r.modelOrAlias.choice.value===0)return!1;const n=r.modelOrAlias?.choice,a=n&&`${n.case}:${n.value}`;return!!a&&!_agSeenChoices.has(a)&&(_agSeenChoices.add(a),!0)});'
        'modelOrAlias:ct(INe,{choice:t.model?{case:"model",value:t.model}:t.recommended?{case:"alias",value:8}:{case:"model",value:0}})'
        's=ct(pIt,{modelOrAlias:ct(INe,{choice:d.model?{case:"model",value:d.model}:d.recommended?{case:"alias",value:8}:{case:"model",value:0}})})'
    )
    $productionAnchor = 'modelOrAlias:ct(INe,{choice:{case:"model",value:t.model}})'
    if ((Get-ExactCount -Content $Content -Value 'function e9a(e,t){return ct(fIt,{label:t.displayName,') -eq 0 -and
        (Get-ExactCount -Content $Content -Value $productionAnchor) -eq 0 -and
        (Get-ExactCount -Content $Content -Value $required[1]) -eq 0) {
        return $true
    }
    foreach ($anchor in $required) {
        if ((Get-ExactCount -Content $Content -Value $anchor) -ne 1) { return $false }
    }
    $true
}

function Test-ContainsAnyExactValue {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string[]]$Values
    )

    foreach ($value in $Values) {
        if ((Get-ExactCount $Content $value) -gt 0) { return $true }
    }
    $false
}

function Test-StableMainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @('_agCompatibilityMode=', $script:LegacyStableAllowlist, $script:Gemini36Allowlist, $script:LegacyGemini36Allowlist, $script:Gemini37Allowlist)
    if (Test-ContainsAnyExactValue -Content $Content -Values $forbidden) {
        return $false
    }
    $catalogEndpointBoundary = 'const g=this.j.getState("uss-lsClientMachineInfos"),b=ZBa(g).filter(A=>A.resource!==""),R={host:"127.0.0.1",resource:"",port:p.httpPort,csrfToken:n,homeDir:_Ba()};b.push(R),this.j.pushUpdate(GBa(b)),await this.a.initialize(p.httpsPort,n)'
    if ((Test-StableCatalogFilterContent -Content $Content) -and
        (Get-ExactCount -Content $Content -Value $catalogEndpointBoundary) -eq 1 -and
        (Get-ExactCount -Content $Content -Value $script:OneLsBridgeHelper) -eq 1 -and
        (Get-ExactCount -Content $Content -Value $script:OneLsBridgedSpawnAnchor) -eq 1) {
        return $true
    }

    $required = @(
        "M=$script:StableAllowlist",
        'clientModelConfigs=(c.clientModelConfigs??[]).filter(m=>M.includes(m.label))',
        'modelLabels:(g.modelLabels??[]).filter(v=>M.includes(v))',
        '}catch{return}const r=t.appliedUpdate;',
        'port:f.httpPort,csrfToken:a,homeDir:sUs()',
        'await this.a.initialize(f.httpsPort,a)'
    )
    foreach ($anchor in $required) {
        if ((Get-ExactCount -Content $Content -Value $anchor) -ne 1) { return $false }
    }
    $true
}

function Test-LegacyStableMainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @('_agCompatibilityMode=', $script:StableAllowlist, $script:Gemini36Allowlist, $script:LegacyGemini36Allowlist, $script:Gemini37Allowlist)
    if ((Get-ExactCount $Content $script:LegacyStableAllowlist) -ne 1 -or
        (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)) {
        return $false
    }
    $stable = $Content.Replace(
        $script:LegacyStableAllowlist,
        $script:StableAllowlist,
        [StringComparison]::Ordinal
    )
    Test-StableMainContent -Content $stable
}

function Test-RecognizedStableMainContent {
    param([Parameter(Mandatory)][string]$Content)
    (Test-StableMainContent -Content $Content) -or (Test-LegacyStableMainContent -Content $Content)
}

function Test-Gemini36MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @($script:StableAllowlist, $script:LegacyStableAllowlist, $script:LegacyGemini36Allowlist)
    if (-not $Content.StartsWith($script:Gemini36MainMarker, [StringComparison]::Ordinal) -or
        (Get-ExactCount $Content $script:Gemini36MainMarker) -ne 1 -or
        (Get-ExactCount $Content '_agCompatibilityMode=') -ne 1 -or
        (Get-ExactCount $Content $script:Gemini36Allowlist) -ne 1 -or
        (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)) {
        return $false
    }
    $stable = $Content.Substring($script:Gemini36MainMarker.Length).Replace(
        $script:Gemini36Allowlist,
        $script:StableAllowlist,
        [StringComparison]::Ordinal
    )
    Test-StableMainContent -Content $stable
}

function Test-LegacyGemini36MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @($script:StableAllowlist, $script:LegacyStableAllowlist, $script:Gemini36Allowlist)
    if (-not $Content.StartsWith($script:Gemini36MainMarker, [StringComparison]::Ordinal) -or
        (Get-ExactCount $Content $script:Gemini36MainMarker) -ne 1 -or
        (Get-ExactCount $Content '_agCompatibilityMode=') -ne 1 -or
        (Get-ExactCount $Content $script:LegacyGemini36Allowlist) -ne 1 -or
        (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)) {
        return $false
    }
    $stable = $Content.Substring($script:Gemini36MainMarker.Length).Replace(
        $script:LegacyGemini36Allowlist,
        $script:StableAllowlist,
        [StringComparison]::Ordinal
    )
    Test-StableMainContent -Content $stable
}

function ConvertFrom-Gemini36MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $allowlist = if (Test-Gemini36MainContent -Content $Content) {
        $script:Gemini36Allowlist
    } elseif (Test-LegacyGemini36MainContent -Content $Content) {
        $script:LegacyGemini36Allowlist
    } else {
        throw 'Gemini 3.6 main.js 结构不完整，拒绝回退。'
    }
    $stable = $Content.Substring($script:Gemini36MainMarker.Length)
    $stable = Replace-ExactOnce $stable $allowlist $script:StableAllowlist 'Gemini 3.6 名单回退'
    if (Test-StableCatalogFilterContent -Content $stable) {
        $stable = Ensure-StableCatalogAliasCompatibility -Content $stable
        $stable = Ensure-StableCatalogDefaultSafety -Content $stable
    }
    if (-not (Test-StableMainContent -Content $stable)) { throw 'Gemini 3.6 main.js 回退校验失败。' }
    $stable
}

function ConvertTo-Gemini36MainContent {
    param([Parameter(Mandatory)][string]$Content)

    if (Test-Gemini36MainContent -Content $Content) { return $Content }
    if (Test-LegacyGemini36MainContent -Content $Content) {
        $Content = ConvertFrom-Gemini36MainContent -Content $Content
    }
    if ((Get-ExactCount $Content '_agCompatibilityMode=') -gt 0) {
        throw 'main.js 已包含未知兼容标记，拒绝覆盖。'
    }
    if (-not (Test-StableMainContent -Content $Content)) {
        throw 'main.js 不是已验证的 Stable 结构，拒绝启用 Gemini 3.6。'
    }
    $result = Replace-ExactOnce $Content $script:StableAllowlist $script:Gemini36Allowlist 'Gemini 3.6 名单'
    $result = $script:Gemini36MainMarker + $result
    if (-not (Test-Gemini36MainContent -Content $result)) { throw 'Gemini 3.6 main.js 补丁后结构校验失败。' }
    $result
}

function Test-Gemini37MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @($script:StableAllowlist, $script:LegacyStableAllowlist, $script:Gemini36Allowlist, $script:LegacyGemini36Allowlist, $script:PreviousGemini37Allowlist, $script:OlderGemini37Allowlist, $script:OldestGemini37Allowlist, $script:LegacyGemini37Allowlist)
    if (-not $Content.StartsWith($script:Gemini37MainMarker, [StringComparison]::Ordinal) -or
        (Get-ExactCount $Content $script:Gemini37MainMarker) -ne 1 -or
        (Get-ExactCount $Content '_agCompatibilityMode=') -ne 1 -or
        (Get-ExactCount $Content $script:Gemini37Allowlist) -ne 1 -or
        (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)) {
        return $false
    }
    $stable = $Content.Substring($script:Gemini37MainMarker.Length).Replace(
        $script:Gemini37Allowlist,
        $script:StableAllowlist,
        [StringComparison]::Ordinal
    )
    Test-StableMainContent -Content $stable
}

function Test-PreviousGemini37MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @($script:StableAllowlist, $script:LegacyStableAllowlist, $script:Gemini36Allowlist, $script:LegacyGemini36Allowlist, $script:Gemini37Allowlist, $script:OlderGemini37Allowlist, $script:OldestGemini37Allowlist, $script:LegacyGemini37Allowlist)
    $Content.StartsWith($script:Gemini37MainMarker, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:Gemini37MainMarker) -eq 1 -and
        (Get-ExactCount $Content $script:PreviousGemini37Allowlist) -eq 1 -and
        -not (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)
}

function Test-OlderGemini37MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @($script:StableAllowlist, $script:LegacyStableAllowlist, $script:Gemini36Allowlist, $script:LegacyGemini36Allowlist, $script:Gemini37Allowlist, $script:PreviousGemini37Allowlist, $script:OldestGemini37Allowlist, $script:LegacyGemini37Allowlist)
    $Content.StartsWith($script:Gemini37MainMarker, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:Gemini37MainMarker) -eq 1 -and
        (Get-ExactCount $Content $script:OlderGemini37Allowlist) -eq 1 -and
        -not (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)
}

function Test-OldestGemini37MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $forbidden = @($script:StableAllowlist, $script:LegacyStableAllowlist, $script:Gemini36Allowlist, $script:LegacyGemini36Allowlist, $script:Gemini37Allowlist, $script:PreviousGemini37Allowlist, $script:OlderGemini37Allowlist, $script:LegacyGemini37Allowlist)
    $Content.StartsWith($script:Gemini37MainMarker, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:Gemini37MainMarker) -eq 1 -and
        (Get-ExactCount $Content $script:OldestGemini37Allowlist) -eq 1 -and
        -not (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)
}

function Test-Gemini37DefaultOverrideSafety {
    param([Parameter(Mandatory)][string]$Content)

    if ((Get-ExactCount -Content $Content -Value 'function _agFilterStatus(e){const t=e?.cascadeModelConfigData;') -eq 0) {
        return $true
    }
    (Get-ExactCount -Content $Content -Value '_agStableStartupLabels') -eq 0 -and
        (Get-ExactCount -Content $Content -Value 'map(a=>`${a.case}:${a.value}`)') -eq 1 -and
        (Get-ExactCount -Content $Content -Value '/^Gemini 3\.7(?: |$)/.test(i?.label??"")') -eq 0 -and
        (Get-ExactCount -Content $Content -Value 't.defaultOverrideModelConfig=i') -le 1
}

function Test-LegacyGemini37MainContent {
    param([Parameter(Mandatory)][string]$Content)
    $forbidden = @($script:StableAllowlist, $script:LegacyStableAllowlist, $script:Gemini36Allowlist, $script:LegacyGemini36Allowlist, $script:Gemini37Allowlist, $script:PreviousGemini37Allowlist, $script:OlderGemini37Allowlist, $script:OldestGemini37Allowlist)
    $Content.StartsWith($script:Gemini37MainMarker, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:Gemini37MainMarker) -eq 1 -and
        (Get-ExactCount $Content $script:LegacyGemini37Allowlist) -eq 1 -and
        -not (Test-ContainsAnyExactValue -Content $Content -Values $forbidden)
}

function ConvertFrom-Gemini37MainContent {
    param([Parameter(Mandatory)][string]$Content)

    $allowlist = if (Test-Gemini37MainContent -Content $Content) {
        $script:Gemini37Allowlist
    } elseif (Test-PreviousGemini37MainContent -Content $Content) {
        $script:PreviousGemini37Allowlist
    } elseif (Test-OlderGemini37MainContent -Content $Content) {
        $script:OlderGemini37Allowlist
    } elseif (Test-OldestGemini37MainContent -Content $Content) {
        $script:OldestGemini37Allowlist
    } elseif (Test-LegacyGemini37MainContent -Content $Content) {
        $script:LegacyGemini37Allowlist
    } else {
        throw 'Gemini 3.7 main.js 结构不完整，拒绝回退。'
    }
    $stable = $Content.Substring($script:Gemini37MainMarker.Length)
    $stable = Replace-ExactOnce $stable $allowlist $script:StableAllowlist 'Gemini 3.7 名单回退'
    if (Test-StableCatalogFilterContent -Content $stable) {
        $stable = Ensure-StableCatalogAliasCompatibility -Content $stable
        $stable = Ensure-StableCatalogDefaultSafety -Content $stable
    }
    if (-not (Test-StableMainContent -Content $stable)) { throw 'Gemini 3.7 main.js 回退校验失败。' }
    $stable
}

function ConvertTo-Gemini37MainContent {
    param([Parameter(Mandatory)][string]$Content)

    if (Test-Gemini37MainContent -Content $Content) { return $Content }
    if ((Test-PreviousGemini37MainContent -Content $Content) -or (Test-OlderGemini37MainContent -Content $Content) -or (Test-OldestGemini37MainContent -Content $Content) -or (Test-LegacyGemini37MainContent -Content $Content)) {
        $Content = ConvertFrom-Gemini37MainContent -Content $Content
        $result = $script:Gemini37MainMarker + (Replace-ExactOnce $Content $script:StableAllowlist $script:Gemini37Allowlist 'Gemini 3.7 名单去重迁移')
        if (-not (Test-Gemini37MainContent -Content $result)) { throw 'Gemini 3.7 旧名单迁移校验失败。' }
        return $result
    }
    if ((Get-ExactCount $Content '_agCompatibilityMode=') -gt 0) {
        throw 'main.js 已包含未知兼容标记，拒绝覆盖。'
    }
    if (-not (Test-StableMainContent -Content $Content)) {
        throw 'main.js 不是已验证的 Stable 结构，拒绝启用 Gemini 3.7。'
    }
    $result = Replace-ExactOnce $Content $script:StableAllowlist $script:Gemini37Allowlist 'Gemini 3.7 名单'
    $result = $script:Gemini37MainMarker + $result
    if (-not (Test-Gemini37MainContent -Content $result)) { throw 'Gemini 3.7 main.js 补丁后结构校验失败。' }
    $result
}

function ConvertTo-StableMainContent {
    param([Parameter(Mandatory)][string]$Content)

    if ((Test-Gemini37MainContent -Content $Content) -or
        (Test-PreviousGemini37MainContent -Content $Content) -or
        (Test-OlderGemini37MainContent -Content $Content) -or
        (Test-OldestGemini37MainContent -Content $Content) -or
        (Test-LegacyGemini37MainContent -Content $Content)) {
        return ConvertFrom-Gemini37MainContent -Content $Content
    }
    if ((Get-ExactCount $Content '_agCompatibilityMode=') -gt 0) {
        return ConvertFrom-Gemini36MainContent -Content $Content
    }
    if (Test-StableMainContent -Content $Content) {
        if (Test-StableCatalogFilterContent -Content $Content) {
            $result = Ensure-StableCatalogAliasCompatibility -Content $Content
            return Ensure-StableCatalogDefaultSafety -Content $result
        }
        return $Content
    }
    if (Test-LegacyStableMainContent -Content $Content) {
        $result = Replace-ExactOnce $Content $script:LegacyStableAllowlist $script:StableAllowlist '旧 Stable 名单升级'
        if (-not (Test-StableMainContent -Content $result)) { throw '旧 Stable main.js 升级校验失败。' }
        return $result
    }

    $rawBoundary = 'async pushUpdate(t){if(!Object.hasOwn(UGe,t.topicName))throw new Error(`Invalid topic: ${t.topicName}`);const r=t.appliedUpdate;'
    if ((Get-ExactCount -Content $Content -Value $rawBoundary) -eq 0) {
        $newAnchor = 'function n9a(e,t,r,n){return ct(oS,{cascadeModelConfigData:r9a(e),disableTelemetry:!(t.telemetryEnabled??!1),userDataCollectionForceDisabled:t.userDataCollectionForceDisabled??!1,name:r.name,email:r.email,userTier:n.userTier})}'
        $newReplacement = 'const _agStableLabels=new Set(["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]);const _agStableStartupLabels=new Set(["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]);function _agFilterStatus(e){const t=e?.cascadeModelConfigData;if(!t)return e;t.clientModelConfigs=(t.clientModelConfigs??[]).filter(r=>_agStableLabels.has(r?.label));const r=new Set(t.clientModelConfigs.map(n=>n.label));for(const n of t.clientModelSorts??[])n.groups=(n.groups??[]).filter(a=>(a.modelLabels=(a.modelLabels??[]).filter(s=>r.has(s)),a.modelLabels.length>0));t.clientModelSorts=(t.clientModelSorts??[]).filter(n=>n.groups.length>0);const n=new Set(t.clientModelConfigs.map(a=>a.modelOrAlias?.choice).filter(a=>a?.case==="model").map(a=>a.value)),a=t.defaultOverrideModelConfig?.modelOrAlias?.choice,i=t.clientModelConfigs.find(s=>_agStableStartupLabels.has(s?.label));return i&&(t.defaultOverrideModelConfig=i),a?.case==="model"&&!n.has(a.value)&&(t.defaultOverrideModelConfig=i??void 0),e}function _agFilterEncoded(e){try{return La(oS,_agFilterStatus(fi(e,oS)))}catch{return La(oS,ct(oS))}}function n9a(e,t,r,n){return _agFilterStatus(ct(oS,{cascadeModelConfigData:r9a(e),disableTelemetry:!(t.telemetryEnabled??!1),userDataCollectionForceDisabled:t.userDataCollectionForceDisabled??!1,name:r.name,email:r.email,userTier:n.userTier}))}'
        $newReplacement = $newReplacement.Replace(
            'const _agStableStartupLabels=new Set(["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]);',
            'const _agStableStartupLabels=new Set(["Claude Opus 4.6 (Thinking)","Claude Sonnet 4.6 (Thinking)"]);',
            [StringComparison]::Ordinal
        )
        $cacheAnchor = 'return a},persist:async(e,t)=>{const r=e.get(Gi);await r.whenReady;const n=La(ea,t);r.store(AMe,n,-1,0)}}'
        $cacheReplacement = 'return a.data?.[WP]?.value&&(a.data[WP].value=_agFilterEncoded(a.data[WP].value)),a},persist:async(e,t)=>{const r=e.get(Gi);await r.whenReady;t.data?.[WP]?.value&&(t.data[WP].value=_agFilterEncoded(t.data[WP].value));const n=La(ea,t);r.store(AMe,n,-1,0)}}'
        $result = $Content
        if ((Get-ExactCount -Content $Content -Value $newAnchor) -eq 1) {
            $result = Replace-ExactOnce $result $newAnchor $newReplacement '新模型目录转换'
            $result = Replace-ExactOnce $result $cacheAnchor $cacheReplacement '新模型缓存边界'
        } elseif (-not (Test-StableCatalogFilterContent -Content $result)) {
            throw '无法识别新版本 main.js 模型过滤结构。'
        }
        $result = Ensure-StableCatalogAliasCompatibility -Content $result
        $result = Ensure-StableCatalogDefaultSafety -Content $result
        $catalogHttpsEndpoint = 'R={host:"127.0.0.1",resource:"",port:p.httpsPort,csrfToken:n,homeDir:_Ba()}'
        $catalogHttpEndpoint = 'R={host:"127.0.0.1",resource:"",port:p.httpPort,csrfToken:n,homeDir:_Ba()}'
        if ((Get-ExactCount -Content $result -Value $catalogHttpsEndpoint) -eq 1) {
            $result = Replace-ExactOnce $result $catalogHttpsEndpoint $catalogHttpEndpoint '新版本本地语言服务器端口'
        } elseif ((Get-ExactCount -Content $result -Value $catalogHttpEndpoint) -ne 1) {
            throw '无法定位新版本本地语言服务器端口。'
        }
        $staleEndpointBoundary = 'const g=this.j.getState("uss-lsClientMachineInfos"),b=ZBa(g),R={host:"127.0.0.1",resource:"",port:p.httpPort,csrfToken:n,homeDir:_Ba()};b.some(A=>A.port===p.httpsPort&&A.csrfToken===n)||(b.push(R),this.j.pushUpdate(GBa(b))),await this.a.initialize(p.httpsPort,n)'
        $stableEndpointBoundary = 'const g=this.j.getState("uss-lsClientMachineInfos"),b=ZBa(g).filter(A=>A.resource!==""),R={host:"127.0.0.1",resource:"",port:p.httpPort,csrfToken:n,homeDir:_Ba()};b.push(R),this.j.pushUpdate(GBa(b)),await this.a.initialize(p.httpsPort,n)'
        if ((Get-ExactCount -Content $result -Value $staleEndpointBoundary) -eq 1) {
            $result = Replace-ExactOnce $result $staleEndpointBoundary $stableEndpointBoundary '本机语言服务器端点缓存'
        } elseif ((Get-ExactCount -Content $result -Value $stableEndpointBoundary) -ne 1) {
            throw '无法定位本机语言服务器端点缓存。'
        }
        if ((Get-ExactCount -Content $result -Value $script:OneLsSpawnAnchor) -eq 1) {
            $bridgeReplacement = $script:OneLsBridgeHelper + $script:OneLsBridgedSpawnAnchor
            $result = Replace-ExactOnce $result $script:OneLsSpawnAnchor $bridgeReplacement 'OneLS Agent Pro 桥接'
        } elseif ((Get-ExactCount -Content $result -Value $script:OneLsBridgeHelper) -ne 1 -or
            (Get-ExactCount -Content $result -Value $script:OneLsBridgedSpawnAnchor) -ne 1) {
            throw '无法定位 OneLS 共享语言服务器启动边界。'
        }
        if (-not (Test-StableMainContent -Content $result)) { throw '新版本 main.js 补丁后结构校验失败。' }
        return $result
    }

    $clearBoundary = 'async pushUpdate(t){if(!Object.hasOwn(UGe,t.topicName))throw new Error(`Invalid topic: ${t.topicName}`);if(t.topicName==="uss-userStatus"&&t.appliedUpdate?.newRow?.value)try{const l=Hs(t.appliedUpdate.newRow.value,WV);l.cascadeModelConfigData=void 0,t.appliedUpdate.newRow.value=$s(WV,l)}catch{}const r=t.appliedUpdate;'
    $subsetBoundary = 'async pushUpdate(t){if(!Object.hasOwn(UGe,t.topicName))throw new Error(`Invalid topic: ${t.topicName}`);if(t.topicName==="uss-userStatus"&&t.appliedUpdate?.newRow?.value)try{const l=Hs(t.appliedUpdate.newRow.value,WV),c=l.cascadeModelConfigData;c&&(c.clientModelConfigs=(c.clientModelConfigs??[]).slice(0,1),c.clientModelSorts=[]),t.appliedUpdate.newRow.value=$s(WV,l)}catch{}const r=t.appliedUpdate;'
    $legacyModels = '["Gemini 3.5 Flash (High)","Gemini 3.5 Flash (Medium)","Gemini 3.5 Flash (Low)","Gemini 3.1 Pro (High)","Gemini 3.1 Pro (Low)"]'
    $legacyBoundary = $subsetBoundary.Replace('(c.clientModelConfigs??[]).slice(0,1)', "(c.clientModelConfigs??[]).filter(m=>$legacyModels.includes(m.label))", [StringComparison]::Ordinal)
    $stableBoundary = $legacyBoundary.Replace($legacyModels, $script:StableAllowlist, [StringComparison]::Ordinal)
    $beforeSorts = "const l=Hs(t.appliedUpdate.newRow.value,WV),c=l.cascadeModelConfigData;c&&(c.clientModelConfigs=(c.clientModelConfigs??[]).filter(m=>$script:StableAllowlist.includes(m.label)),c.clientModelSorts=[])"
    $afterSorts = "const l=Hs(t.appliedUpdate.newRow.value,WV),c=l.cascadeModelConfigData,M=$script:StableAllowlist;c&&(c.clientModelConfigs=(c.clientModelConfigs??[]).filter(m=>M.includes(m.label)),c.clientModelSorts=(c.clientModelSorts??[]).map(m=>({...m,groups:(m.groups??[]).map(g=>({...g,modelLabels:(g.modelLabels??[]).filter(v=>M.includes(v))})).filter(g=>g.modelLabels.length)})).filter(m=>m.groups.length))"

    $result = Replace-ExactOnce $Content $rawBoundary $clearBoundary 'userStatus 边界'
    $result = Replace-ExactOnce $result $clearBoundary $subsetBoundary '模型子集'
    $result = Replace-ExactOnce $result $subsetBoundary $legacyBoundary '旧版名单'
    $result = Replace-ExactOnce $result $legacyBoundary $stableBoundary '稳定名单'
    $result = Replace-ExactOnce $result $beforeSorts $afterSorts '模型排序'

    $allowlistIndex = $result.IndexOf("M=$script:StableAllowlist", [StringComparison]::Ordinal)
    $catchIndex = $result.IndexOf('}catch{}', $allowlistIndex, [StringComparison]::Ordinal)
    if ($allowlistIndex -lt 0 -or $catchIndex -lt 0 -or ($catchIndex - $allowlistIndex) -gt 800) {
        throw '无法定位稳定模型过滤的 fail-closed 边界。'
    }
    $result = $result.Substring(0, $catchIndex) + '}catch{return}' + $result.Substring($catchIndex + 8)

    $httpsEndpoint = 'y={host:"127.0.0.1",resource:"",port:f.httpsPort,csrfToken:a,homeDir:sUs()};b.some(v=>v.port===f.httpsPort&&v.csrfToken===a)'
    $httpEndpoint = 'y={host:"127.0.0.1",resource:"",port:f.httpPort,csrfToken:a,homeDir:sUs()};b.some(v=>v.port===f.httpPort&&v.csrfToken===a)'
    $result = Replace-ExactOnce $result $httpsEndpoint $httpEndpoint '本地语言服务器端口'

    if (-not (Test-StableMainContent -Content $result)) { throw 'main.js 补丁后结构校验失败。' }
    $result
}

function Get-StableWorkbenchProtocol {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('legacy-http-v1', 'catalog-filter-https-v1', 'catalog-filter-http-v2', 'catalog-dual-transport-v3')]
        [string]$Adapter
    )

    if ($Adapter -eq 'catalog-dual-transport-v3') { return 'Dual' }
    'Http'
}

function Resolve-StableAdapter {
    param([Parameter(Mandatory)][string]$MainContent)

    if (-not (Test-StableMainContent -Content $MainContent)) { throw 'main.js 不符合稳定结构，无法选择适配器。' }
    $legacyEndpoint = 'port:f.httpPort,csrfToken:a,homeDir:sUs()'
    if ((Get-ExactCount -Content $MainContent -Value $legacyEndpoint) -eq 1) { return 'legacy-http-v1' }

    $catalogFilter = 'function _agFilterStatus(e){const t=e?.cascadeModelConfigData;'
    $httpEndpoint = 'port:p.httpPort,csrfToken:n,homeDir:_Ba()'
    if ((Get-ExactCount -Content $MainContent -Value $catalogFilter) -eq 1 -and
        (Get-ExactCount -Content $MainContent -Value $httpEndpoint) -eq 1) {
        return 'catalog-dual-transport-v3'
    }
    throw '无法根据 main.js 端口契约选择 workbench 适配器。'
}

function Test-StableWorkbenchContent {
    param(
        [Parameter(Mandatory)][string]$Content,
        [string]$Adapter = 'legacy-http-v1'
    )

    $protocol = Get-StableWorkbenchProtocol -Adapter $Adapter
    $http = 'get baseUrl(){return`http://127.0.0.1:${this.port}`}'
    $https = 'get baseUrl(){return`https://127.0.0.1:${this.port}`}'
    if ($protocol -eq 'Dual') {
        $constructor = 'constructor(t,e,i=!1){this.port=t,this.csrfToken=e,this.useHttp=i}'
        $dynamic = 'get baseUrl(){return`${this.useHttp?"http":"https"}://127.0.0.1:${this.port}`}'
        $oneLs = 'this.n=new cIo(o.port,o.csrfToken,!0)'
        return (Get-ExactCount $Content $constructor) -eq 1 -and
            (Get-ExactCount $Content $dynamic) -eq 1 -and
            (Get-ExactCount $Content $oneLs) -eq 1 -and
            (Get-ExactCount $Content $http) -eq 0 -and
            (Get-ExactCount $Content $https) -eq 0
    }
    $expected = if ($protocol -eq 'Http') { $http } else { $https }
    $rejected = if ($protocol -eq 'Http') { $https } else { $http }
    (Get-ExactCount $Content $expected) -eq 1 -and (Get-ExactCount $Content $rejected) -eq 0
}

function Test-Gemini36WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    $Content.StartsWith($script:Gemini36WorkbenchPrefix, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:Gemini36WorkbenchPrefix) -eq 1 -and
        (Get-ExactCount $Content '_agCompatibilityMode=') -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36QbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36DbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36QbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36DbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36ModelEncoderAnchor) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36RequestedModelAnchor) -eq 1
}

function Test-LegacyGemini36WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    $Content.StartsWith($script:LegacyGemini36WorkbenchPrefix, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:LegacyGemini36WorkbenchPrefix) -eq 1 -and
        (Get-ExactCount $Content '_agCompatibilityMode=') -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36QbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36DbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36QbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36DbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36ModelEncoderAnchor) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36RequestedModelAnchor) -eq 1
}

function ConvertFrom-Gemini36WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    $prefix = if (Test-Gemini36WorkbenchContent -Content $Content) {
        $script:Gemini36WorkbenchPrefix
    } elseif (Test-LegacyGemini36WorkbenchContent -Content $Content) {
        $script:LegacyGemini36WorkbenchPrefix
    } else {
        throw 'Gemini 3.6 workbench 结构不完整，拒绝回退。'
    }
    $stable = $Content.Substring($prefix.Length)
    $stable = Replace-ExactOnce $stable $script:Gemini36QbReplacement $script:Gemini36QbAnchor 'Gemini 3.6 qb 回退'
    $stable = Replace-ExactOnce $stable $script:Gemini36DbReplacement $script:Gemini36DbAnchor 'Gemini 3.6 Db 回退'
    $stable
}

function ConvertTo-Gemini36WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    if (Test-Gemini36WorkbenchContent -Content $Content) { return $Content }
    if (Test-LegacyGemini36WorkbenchContent -Content $Content) {
        $Content = ConvertFrom-Gemini36WorkbenchContent -Content $Content
    }
    if ((Get-ExactCount $Content '_agCompatibilityMode=') -gt 0) {
        throw 'workbench 已包含不完整的 Gemini 3.6 标记，拒绝覆盖。'
    }
    $result = Replace-ExactOnce $Content $script:Gemini36QbAnchor $script:Gemini36QbReplacement 'Gemini 3.6 qb'
    $result = Replace-ExactOnce $result $script:Gemini36DbAnchor $script:Gemini36DbReplacement 'Gemini 3.6 Db'
    $result = $script:Gemini36WorkbenchPrefix + $result
    if (-not (Test-Gemini36WorkbenchContent -Content $result)) { throw 'Gemini 3.6 workbench 补丁后结构校验失败。' }
    $result
}

function Test-Gemini37WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    $Content.StartsWith($script:Gemini37WorkbenchPrefix, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:Gemini37WorkbenchPrefix) -eq 1 -and
        (Get-ExactCount $Content '_agCompatibilityMode=') -eq 1 -and
        (Get-ExactCount $Content $script:Gemini37QbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini37DbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36QbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36DbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36RequestedModelAnchor) -eq 1
}

function Test-PreviousGemini37WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    $Content.StartsWith($script:PreviousGemini37WorkbenchPrefix, [StringComparison]::Ordinal) -and
        (Get-ExactCount $Content $script:PreviousGemini37WorkbenchPrefix) -eq 1 -and
        (Get-ExactCount $Content '_agCompatibilityMode=') -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36QbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36DbReplacement) -eq 1
}

function Test-LegacyGemini37WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    $prefixCount = (Get-ExactCount $Content $script:LegacyGemini37WorkbenchPrefix) +
        (Get-ExactCount $Content $script:OlderGemini37WorkbenchPrefix)
    ($Content.StartsWith($script:LegacyGemini37WorkbenchPrefix, [StringComparison]::Ordinal) -or
        $Content.StartsWith($script:OlderGemini37WorkbenchPrefix, [StringComparison]::Ordinal)) -and
        $prefixCount -eq 1 -and
        (Get-ExactCount $Content '_agCompatibilityMode=') -eq 1 -and
        (Get-ExactCount $Content $script:LegacyGemini37QbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:LegacyGemini37DbReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:LegacyGemini37ModelOptionReplacement) -eq 1 -and
        (Get-ExactCount $Content $script:Gemini36QbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36DbAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:LegacyGemini37ModelOptionAnchor) -eq 0 -and
        (Get-ExactCount $Content $script:Gemini36RequestedModelAnchor) -eq 1
}

function ConvertFrom-Gemini37WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    if (Test-Gemini37WorkbenchContent -Content $Content) {
        $stable = $Content.Substring($script:Gemini37WorkbenchPrefix.Length)
        $stable = Replace-ExactOnce $stable $script:Gemini37QbReplacement $script:Gemini36QbAnchor 'Gemini 3.7/3.6 qb 回退'
        return Replace-ExactOnce $stable $script:Gemini37DbReplacement $script:Gemini36DbAnchor 'Gemini 3.7/3.6 Db 回退'
    }
    if (Test-PreviousGemini37WorkbenchContent -Content $Content) {
        $stable = $Content.Substring($script:PreviousGemini37WorkbenchPrefix.Length)
        $stable = Replace-ExactOnce $stable $script:Gemini36QbReplacement $script:Gemini36QbAnchor '上一版 Gemini 3.7/3.6 qb 回退'
        return Replace-ExactOnce $stable $script:Gemini36DbReplacement $script:Gemini36DbAnchor '上一版 Gemini 3.7/3.6 Db 回退'
    }
    if (-not (Test-LegacyGemini37WorkbenchContent -Content $Content)) {
        throw 'Gemini 3.7 workbench 结构不完整，拒绝回退。'
    }
    $prefix = if ($Content.StartsWith($script:LegacyGemini37WorkbenchPrefix, [StringComparison]::Ordinal)) {
        $script:LegacyGemini37WorkbenchPrefix
    } else {
        $script:OlderGemini37WorkbenchPrefix
    }
    $stable = $Content.Substring($prefix.Length)
    $stable = Replace-ExactOnce $stable $script:LegacyGemini37QbReplacement $script:Gemini36QbAnchor '旧 Gemini 3.7 qb 回退'
    $stable = Replace-ExactOnce $stable $script:LegacyGemini37DbReplacement $script:Gemini36DbAnchor '旧 Gemini 3.7 Db 回退'
    $stable = Replace-ExactOnce $stable $script:LegacyGemini37ModelOptionReplacement $script:LegacyGemini37ModelOptionAnchor '旧 Gemini 3.7 模型 ID 登记回退'
    $stable
}

function ConvertTo-Gemini37WorkbenchContent {
    param([Parameter(Mandatory)][string]$Content)

    if (Test-Gemini37WorkbenchContent -Content $Content) { return $Content }
    if ((Test-PreviousGemini37WorkbenchContent -Content $Content) -or (Test-LegacyGemini37WorkbenchContent -Content $Content)) {
        $Content = ConvertFrom-Gemini37WorkbenchContent -Content $Content
    }
    if ((Get-ExactCount $Content '_agCompatibilityMode=') -gt 0) {
        throw 'workbench 已包含未知兼容标记，拒绝覆盖。'
    }
    $isStable = (Test-StableWorkbenchContent -Content $Content -Adapter 'legacy-http-v1') -or
        (Test-StableWorkbenchContent -Content $Content -Adapter 'catalog-dual-transport-v3')
    if (-not $isStable) { throw 'Gemini 3.7 目标 Workbench 必须来自已验证 Stable 结构。' }
    $result = Replace-ExactOnce $Content $script:Gemini36QbAnchor $script:Gemini37QbReplacement 'Gemini 3.7/3.6 qb'
    $result = Replace-ExactOnce $result $script:Gemini36DbAnchor $script:Gemini37DbReplacement 'Gemini 3.7/3.6 Db'
    $result = $script:Gemini37WorkbenchPrefix + $result
    if (-not (Test-Gemini37WorkbenchContent -Content $result)) { throw 'Gemini 3.7/3.6 workbench 补丁后结构校验失败。' }
    $result
}

function Get-Gemini37ContentGeneration {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][ValidateSet('Main', 'Workbench')][string]$Kind
    )

    if ($Kind -eq 'Main') {
        if (Test-Gemini37MainContent -Content $Content) { return 'Current' }
        if (Test-PreviousGemini37MainContent -Content $Content) { return 'Legacy' }
        if (Test-OlderGemini37MainContent -Content $Content) { return 'Legacy' }
        if (Test-OldestGemini37MainContent -Content $Content) { return 'Legacy' }
        if (Test-LegacyGemini37MainContent -Content $Content) { return 'Legacy' }
        return $null
    }
    if (Test-Gemini37WorkbenchContent -Content $Content) { return 'Current' }
    if (Test-PreviousGemini37WorkbenchContent -Content $Content) { return 'Legacy' }
    if (Test-LegacyGemini37WorkbenchContent -Content $Content) { return 'Legacy' }
    $null
}

function Get-Gemini36ContentGeneration {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][ValidateSet('Main', 'Workbench')][string]$Kind
    )

    if ($Kind -eq 'Main') {
        if (Test-Gemini36MainContent -Content $Content) { return 'Current' }
        if (Test-LegacyGemini36MainContent -Content $Content) { return 'Legacy' }
        return $null
    }
    if (Test-Gemini36WorkbenchContent -Content $Content) { return 'Current' }
    if (Test-LegacyGemini36WorkbenchContent -Content $Content) { return 'Legacy' }
    $null
}

function Assert-Gemini36GenerationPair {
    param(
        [Parameter(Mandatory)][string]$MainContent,
        [Parameter(Mandatory)][string]$WorkbenchContent
    )

    $mainGeneration = Get-Gemini36ContentGeneration -Content $MainContent -Kind Main
    $workbenchGeneration = Get-Gemini36ContentGeneration -Content $WorkbenchContent -Kind Workbench
    if ($mainGeneration -ne $workbenchGeneration) {
        throw 'main.js 与 workbench 的 Gemini 3.6 补丁代际不一致，拒绝转换。'
    }
}

function Assert-CompatibilityGenerationPair {
    param(
        [Parameter(Mandatory)][string]$MainContent,
        [Parameter(Mandatory)][string]$WorkbenchContent
    )

    Assert-Gemini36GenerationPair -MainContent $MainContent -WorkbenchContent $WorkbenchContent
    $main37 = Get-Gemini37ContentGeneration -Content $MainContent -Kind Main
    $workbench37 = Get-Gemini37ContentGeneration -Content $WorkbenchContent -Kind Workbench
    $stableWorkbench = $false
    if ($null -ne $main37 -and $null -eq $workbench37) {
        $stableMain = ConvertFrom-Gemini37MainContent -Content $MainContent
        $stableWorkbench = Test-StableWorkbenchContent -Content $WorkbenchContent -Adapter (Resolve-StableAdapter -MainContent $stableMain)
    }
    if (($null -eq $main37) -ne ($null -eq $workbench37) -and -not $stableWorkbench) {
        throw 'main.js 与 workbench 的 Gemini 3.7 模式不一致，拒绝转换。'
    }
    $main36 = Get-Gemini36ContentGeneration -Content $MainContent -Kind Main
    $workbench36 = Get-Gemini36ContentGeneration -Content $WorkbenchContent -Kind Workbench
    if (($null -ne $main36 -or $null -ne $workbench36) -and ($null -ne $main37 -or $null -ne $workbench37)) {
        throw 'main.js 与 workbench 混入不同 Gemini 兼容模式，拒绝转换。'
    }
}

function Test-RecognizedStablePair {
    param(
        [Parameter(Mandatory)][string]$MainContent,
        [Parameter(Mandatory)][string]$WorkbenchContent
    )

    if (-not (Test-RecognizedStableMainContent -Content $MainContent)) { return $false }
    $stableMain = ConvertTo-StableMainContent -Content $MainContent
    $adapter = Resolve-StableAdapter -MainContent $stableMain
    Test-StableWorkbenchContent -Content $WorkbenchContent -Adapter $adapter
}

function Get-InstalledCompatibilityMode {
    param(
        [string]$InstallRoot,
        [string]$MainContent,
        [string]$WorkbenchContent
    )

    if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
        if ($PSBoundParameters.ContainsKey('MainContent') -or $PSBoundParameters.ContainsKey('WorkbenchContent')) {
            throw 'InstallRoot 与内存内容参数不能同时使用。'
        }
        $files = Get-InstallFiles -InstallRoot $InstallRoot
        $MainContent = [IO.File]::ReadAllText($files.Main)
        $WorkbenchContent = [IO.File]::ReadAllText($files.Workbench)
    }
    if (-not $PSBoundParameters.ContainsKey('InstallRoot') -and
        (-not $PSBoundParameters.ContainsKey('MainContent') -or -not $PSBoundParameters.ContainsKey('WorkbenchContent'))) {
        throw '必须提供 InstallRoot，或同时提供 MainContent 与 WorkbenchContent。'
    }

    Assert-CompatibilityGenerationPair -MainContent $MainContent -WorkbenchContent $WorkbenchContent
    $main37 = Get-Gemini37ContentGeneration -Content $MainContent -Kind Main
    if ($null -ne $main37) { return 'Gemini37' }
    $mainGeneration = Get-Gemini36ContentGeneration -Content $MainContent -Kind Main
    if ($null -ne $mainGeneration) { return 'Gemini36' }
    if (Test-RecognizedStablePair -MainContent $MainContent -WorkbenchContent $WorkbenchContent) { return 'Stable' }
    throw '无法识别已安装兼容模式。'
}

function ConvertTo-StableWorkbenchContent {
    param(
        [Parameter(Mandatory)][string]$Content,
        [string]$Adapter = 'legacy-http-v1'
    )

    if ((Test-Gemini37WorkbenchContent -Content $Content) -or
        (Test-PreviousGemini37WorkbenchContent -Content $Content) -or
        (Test-LegacyGemini37WorkbenchContent -Content $Content) -or
        $Content.StartsWith($script:LegacyGemini37WorkbenchPrefix, [StringComparison]::Ordinal)) {
        $Content = ConvertFrom-Gemini37WorkbenchContent -Content $Content
    } elseif ((Get-ExactCount $Content '_agCompatibilityMode=') -gt 0) {
        $Content = ConvertFrom-Gemini36WorkbenchContent -Content $Content
    }
    if (Test-StableWorkbenchContent -Content $Content -Adapter $Adapter) { return $Content }
    $protocol = Get-StableWorkbenchProtocol -Adapter $Adapter
    $http = 'get baseUrl(){return`http://127.0.0.1:${this.port}`}'
    $https = 'get baseUrl(){return`https://127.0.0.1:${this.port}`}'
    if ($protocol -eq 'Dual') {
        $constructor = 'constructor(t,e){this.port=t,this.csrfToken=e}'
        $dualConstructor = 'constructor(t,e,i=!1){this.port=t,this.csrfToken=e,this.useHttp=i}'
        $dynamic = 'get baseUrl(){return`${this.useHttp?"http":"https"}://127.0.0.1:${this.port}`}'
        $oneLs = 'this.n=new cIo(o.port,o.csrfToken)'
        $result = Replace-ExactOnce $Content $constructor $dualConstructor '工作台双协议构造器'
        $sourceProtocol = if ((Get-ExactCount $result $http) -eq 1) { $http } else { $https }
        $result = Replace-ExactOnce $result $sourceProtocol $dynamic '工作台双协议地址'
        $result = Replace-ExactOnce $result $oneLs 'this.n=new cIo(o.port,o.csrfToken,!0)' 'USS 单实例 HTTP 链路'
        if (-not (Test-StableWorkbenchContent -Content $result -Adapter $Adapter)) { throw 'workbench 双协议补丁后结构校验失败。' }
        return $result
    }
    $before = if ($protocol -eq 'Http') { $https } else { $http }
    $after = if ($protocol -eq 'Http') { $http } else { $https }
    $result = Replace-ExactOnce $Content $before $after '工作台本地地址协议'
    if (-not (Test-StableWorkbenchContent -Content $result -Adapter $Adapter)) { throw 'workbench 补丁后结构校验失败。' }
    $result
}

function Test-RestartSafeExtensionContent {
    param([Parameter(Mandatory)][string]$Content)

    $early = [regex]::Matches($Content, $script:AuthEarlyPattern)
    $safe = [regex]::Matches($Content, $script:AuthSafePattern)
    $early.Count -eq 0 -and $safe.Count -eq 1
}

function ConvertTo-RestartSafeExtensionContent {
    param([Parameter(Mandatory)][string]$Content)

    if (Test-RestartSafeExtensionContent -Content $Content) { return $Content }
    $early = [regex]::Matches($Content, $script:AuthEarlyPattern)
    $ready = [regex]::Matches($Content, $script:AuthReadyPattern)
    if ($early.Count -ne 1) { throw "用户状态启动锚点期望 1 次，实际 $($early.Count) 次。" }
    if ($ready.Count -ne 1) { throw "语言服务器就绪锚点期望 1 次，实际 $($ready.Count) 次。" }

    $updater = $early[0].Groups['updater'].Value
    $withoutEarlyStart = $early[0].Groups['prefix'].Value + $early[0].Groups['suffix'].Value
    $afterReadyStart = $ready[0].Groups['prefix'].Value + $updater + $ready[0].Groups['suffix'].Value
    $result = Replace-ExactOnce $Content $early[0].Value $withoutEarlyStart '用户状态提前启动'
    $result = Replace-ExactOnce $result $ready[0].Value $afterReadyStart '语言服务器就绪后启动用户状态'
    if (-not (Test-RestartSafeExtensionContent -Content $result)) { throw 'extension.js 登录重启补丁后结构校验失败。' }
    $result
}

function Write-Utf8Atomic {
    param([string]$Path, [string]$Content)
    $temporary = "$Path.agcompat.tmp"
    [IO.File]::WriteAllText($temporary, $Content, [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Copy-FileAtomic {
    param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination)

    $temporary = "$Destination.agcompat.tmp"
    try {
        Copy-Item -LiteralPath $Source -Destination $temporary -Force
        Move-Item -LiteralPath $temporary -Destination $Destination -Force
    }
    finally {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
    }
}

function Get-WorkbenchChecksum {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    [Convert]::ToBase64String([Security.Cryptography.SHA256]::HashData($bytes)).TrimEnd('=')
}

function Test-JavaScriptSyntax {
    param([string]$Content, [string]$Name)

    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($null -eq $node) { throw '未找到 Node.js，无法执行候选 JavaScript 语法检查。' }
    $extension = if ($Content -match '(?m)(^|\s)(import|export)(?:\s|\{)') { '.mjs' } else { '.js' }
    $temporary = Join-Path ([IO.Path]::GetTempPath()) ("AntigravityCompat-$([guid]::NewGuid().ToString('N'))$extension")
    try {
        [IO.File]::WriteAllText($temporary, $Content, [Text.UTF8Encoding]::new($false))
        $output = & $node.Source --check $temporary 2>&1
        if ($LASTEXITCODE -ne 0) { throw "$Name JavaScript 语法检查失败：$output" }
    }
    finally {
        Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
    }
}

function Update-StableProduct {
    param([string]$ProductPath, [string]$WorkbenchPath)

    $product = Get-Content -LiteralPath $ProductPath -Raw | ConvertFrom-Json
    $product.ideVersion = $script:StableIdeVersion
    $product.date = $script:StableDate
    if ($null -eq $product.checksums) {
        $product.checksums = [pscustomobject]@{}
    }
    $name = 'vs/workbench/workbench.desktop.main.js'
    $value = Get-WorkbenchChecksum -Path $WorkbenchPath
    $property = $product.checksums.PSObject.Properties[$name]
    if ($null -eq $property) {
        $product.checksums | Add-Member -NotePropertyName $name -NotePropertyValue $value
    } else {
        $property.Value = $value
    }
    Write-Utf8Atomic -Path $ProductPath -Content ($product | ConvertTo-Json -Depth 100)
}

function Assert-InstallLayout {
    param($Files)
    foreach ($path in @($Files.Exe, $Files.Main, $Files.Workbench, $Files.Extension, $Files.Product)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "缺少安装文件：$path" }
    }
    if (-not [string]::IsNullOrWhiteSpace($Files.AgentProSource) -and
        -not (Test-Path -LiteralPath $Files.AgentProSource -PathType Leaf)) {
        throw "缺少 Agent Pro source.js：$($Files.AgentProSource)"
    }
}

function Get-ProcessPathSnapshot {
    $paths = @{}
    try {
        foreach ($item in @(Get-CimInstance Win32_Process -Filter "Name='Antigravity.exe' OR Name='language_server_windows_x64.exe' OR Name='language_server_windows.exe'" -ErrorAction Stop)) {
            if (-not [string]::IsNullOrWhiteSpace($item.ExecutablePath)) { $paths[[int]$item.ProcessId] = $item.ExecutablePath }
        }
    } catch { }
    $paths
}

function Get-ComparableProcessPath {
    param([Parameter(Mandatory)]$Process, [Parameter(Mandatory)][hashtable]$Snapshot)
    $path = try { $Process.Path } catch { $null }
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $Snapshot[[int]$Process.Id] }
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    [IO.Path]::GetFullPath($path)
}

function Assert-NoAntigravityProcesses {
    param([string]$InstallRoot)

    $names = @('Antigravity', 'language_server_windows_x64', 'language_server_windows')
    $root = if ([string]::IsNullOrWhiteSpace($InstallRoot)) { $null } else { [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/') }
    $snapshot = Get-ProcessPathSnapshot
    $running = @(Get-Process -Name $names -ErrorAction SilentlyContinue | Where-Object {
        if (@($_.Threads).Count -eq 0) { return $false }
        if ($null -eq $root) { return $true }
        $processPath = Get-ComparableProcessPath -Process $_ -Snapshot $snapshot
        if ([string]::IsNullOrWhiteSpace($processPath)) { return $true }
        $fullPath = [IO.Path]::GetFullPath($processPath)
        $fullPath.Equals((Join-Path $root 'Antigravity.exe'), [StringComparison]::OrdinalIgnoreCase) -or
            $fullPath.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($running) { throw '请先关闭 Antigravity 和语言服务器，再应用稳定模式。' }
}

function Get-ScopedAntigravityProcesses {
    param([Parameter(Mandatory)][string]$InstallRoot)

    $root = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
    $names = @('Antigravity', 'language_server_windows_x64', 'language_server_windows')
    $snapshot = Get-ProcessPathSnapshot
    @(Get-Process -Name $names -ErrorAction SilentlyContinue | Where-Object {
        if (@($_.Threads).Count -eq 0) { return $false }
        $processPath = Get-ComparableProcessPath -Process $_ -Snapshot $snapshot
        if ([string]::IsNullOrWhiteSpace($processPath)) { return $false }
        $fullPath = [IO.Path]::GetFullPath($processPath)
        $fullPath.Equals((Join-Path $root 'Antigravity.exe'), [StringComparison]::OrdinalIgnoreCase) -or
            $fullPath.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
    })
}

function Stop-ScopedAntigravityProcesses {
    param([Parameter(Mandatory)][string]$InstallRoot)

    $running = @(Get-ScopedAntigravityProcesses -InstallRoot $InstallRoot)
    foreach ($process in $running) {
        try { if ($process.MainWindowHandle -ne 0) { [void]$process.CloseMainWindow() } } catch { }
    }
    $deadline = [DateTime]::UtcNow.AddSeconds(5)
    do {
        $running = @(Get-ScopedAntigravityProcesses -InstallRoot $InstallRoot)
        if ($running.Count -eq 0) { return }
        Start-Sleep -Milliseconds 200
    } while ([DateTime]::UtcNow -lt $deadline)
    foreach ($process in $running) {
        try { Stop-Process -Id $process.Id -Force -ErrorAction Stop } catch { }
    }
    Start-Sleep -Milliseconds 300
    Assert-NoAntigravityProcesses -InstallRoot $InstallRoot
}

function Get-DatabasePaths {
    $root = Join-Path $env:APPDATA 'Antigravity\User\globalStorage'
    @(
        (Join-Path $root 'state.vscdb'),
        (Join-Path $root 'state.vscdb-wal'),
        (Join-Path $root 'state.vscdb-shm')
    )
}

function New-StableBackup {
    param($Files, [string]$BackupRoot, [switch]$IncludeModelCache)

    $folder = Join-Path $BackupRoot ("stable-" + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $sources = @($Files.Main, $Files.Workbench, $Files.Extension, $Files.Product, $Files.Bridge)
    foreach ($name in @('AgentProSource', 'AgentProCompat')) {
        $value = $Files.PSObject.Properties[$name]?.Value
        if (-not [string]::IsNullOrWhiteSpace($value)) { $sources += $value }
    }
    if ($IncludeModelCache) {
        $sources += @(Get-DatabasePaths | Where-Object { Test-Path -LiteralPath $_ })
    }
    $entries = foreach ($source in $sources) {
        if ((Test-Path -LiteralPath $source) -and -not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "备份目标不是文件：$source"
        }
        $existed = Test-Path -LiteralPath $source -PathType Leaf
        $name = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($source))).Substring(0, 12) + '-' + [IO.Path]::GetFileName($source)
        $destination = if ($existed) { Join-Path $folder $name } else { $null }
        if ($existed) { Copy-Item -LiteralPath $source -Destination $destination -Force }
        [pscustomobject]@{
            source = $source
            existed = $existed
            backup = $destination
            sha256 = if ($existed) { Get-Sha256 $source } else { $null }
        }
    }
    $manifest = [pscustomobject]@{ createdUtc = [DateTime]::UtcNow.ToString('O'); installRoot = $Files.Root; entries = @($entries) }
    Write-Utf8Atomic -Path (Join-Path $folder 'manifest.json') -Content ($manifest | ConvertTo-Json -Depth 10)
    $folder
}

function Restore-StableBackup {
    param([Parameter(Mandatory)][string]$BackupDirectory)

    $manifestPath = Join-Path $BackupDirectory 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) { throw '备份清单不存在。' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    Assert-NoAntigravityProcesses -InstallRoot $manifest.installRoot
    foreach ($entry in $manifest.entries) {
        $existedProperty = $entry.PSObject.Properties['existed']
        $existed = $null -eq $existedProperty -or [bool]$existedProperty.Value
        if ($existed -and (Get-Sha256 $entry.backup) -ne $entry.sha256) { throw "备份哈希不匹配：$($entry.backup)" }
    }
    foreach ($entry in $manifest.entries) {
        $existedProperty = $entry.PSObject.Properties['existed']
        $existed = $null -eq $existedProperty -or [bool]$existedProperty.Value
        if ($existed) {
            Copy-FileAtomic -Source $entry.backup -Destination $entry.source
            if ((Get-Sha256 $entry.source) -ne $entry.sha256) { throw "恢复哈希不匹配：$($entry.source)" }
        } elseif (Test-Path -LiteralPath $entry.source -PathType Leaf) {
            Remove-Item -LiteralPath $entry.source -Force
        } elseif (Test-Path -LiteralPath $entry.source) {
            throw "恢复目标不是文件：$($entry.source)"
        }
    }
    "已恢复备份：$BackupDirectory"
}

function Clear-StableModelCache {
    param([string]$DatabasePath)

    $database = if ([string]::IsNullOrWhiteSpace($DatabasePath)) { (Get-DatabasePaths)[0] } else { $DatabasePath }
    if (-not (Test-Path -LiteralPath $database)) { return '未发现旧版模型缓存，跳过。' }
    $sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if ($null -eq $sqlite) { throw '未找到 sqlite3，无法安全清理旧模型缓存。' }
    $sql = "DELETE FROM ItemTable WHERE key = 'antigravityUnifiedStateSync.modelPreferences';"
    & $sqlite.Source $database $sql
    if ($LASTEXITCODE -ne 0) { throw "模型缓存清理失败，sqlite3 退出码：$LASTEXITCODE" }
    '已清除 modelPreferences；userStatus 与登录状态已保留。'
}

function Get-CompatibilityCandidate {
    param(
        [Parameter(Mandatory)][string]$MainContent,
        [Parameter(Mandatory)][string]$WorkbenchContent,
        [Parameter(Mandatory)][string]$ExtensionContent,
        [Parameter(Mandatory)][ValidateSet('Stable', 'Gemini36', 'Gemini37')][string]$Mode
    )

    Assert-CompatibilityGenerationPair -MainContent $MainContent -WorkbenchContent $WorkbenchContent
    $stableMain = ConvertTo-StableMainContent -Content $MainContent
    $adapter = Resolve-StableAdapter -MainContent $stableMain
    $stableWorkbench = ConvertTo-StableWorkbenchContent -Content $WorkbenchContent -Adapter $adapter
    $targetMain = switch ($Mode) {
        'Gemini36' { ConvertTo-Gemini36MainContent -Content $stableMain }
        'Gemini37' { ConvertTo-Gemini37MainContent -Content $stableMain }
        default { $stableMain }
    }
    $targetWorkbench = switch ($Mode) {
        'Gemini36' { ConvertTo-Gemini36WorkbenchContent -Content $stableWorkbench }
        'Gemini37' { ConvertTo-Gemini37WorkbenchContent -Content $stableWorkbench }
        default { $stableWorkbench }
    }
    [pscustomobject]@{
        Mode = $Mode
        Main = $targetMain
        Workbench = $targetWorkbench
        Extension = ConvertTo-RestartSafeExtensionContent -Content $ExtensionContent
        Adapter = $adapter
    }
}

function Get-OptionalFileHash {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return Get-Sha256 $Path }
    $null
}

function Get-InstalledModeOrUnknown {
    param([string]$MainContent, [string]$WorkbenchContent)
    try {
        Get-InstalledCompatibilityMode -MainContent $MainContent -WorkbenchContent $WorkbenchContent
    } catch {
        'Unknown'
    }
}

function Test-CompatibilityWorkbenchContent {
    param(
        [string]$Content,
        [ValidateSet('Stable', 'Gemini36', 'Gemini37')][string]$Mode,
        [string]$Adapter
    )

    if ($Mode -eq 'Stable') {
        if ([string]::IsNullOrWhiteSpace($Adapter)) { return $false }
        return Test-StableWorkbenchContent -Content $Content -Adapter $Adapter
    }
    if ($Mode -eq 'Gemini37') {
        if ([string]::IsNullOrWhiteSpace($Adapter) -or -not (Test-Gemini37WorkbenchContent -Content $Content)) { return $false }
        $stable = ConvertFrom-Gemini37WorkbenchContent -Content $Content
        return Test-StableWorkbenchContent -Content $stable -Adapter $Adapter
    }
    if (-not (Test-Gemini36WorkbenchContent -Content $Content)) { return $false }
    if ([string]::IsNullOrWhiteSpace($Adapter)) { return $false }
    $stable = ConvertFrom-Gemini36WorkbenchContent -Content $Content
    Test-StableWorkbenchContent -Content $stable -Adapter $Adapter
}

function Get-CompatibilityStructure {
    param(
        [string]$MainContent,
        [string]$WorkbenchContent,
        [string]$ExtensionContent,
        [ValidateSet('Stable', 'Gemini36', 'Gemini37')][string]$Mode,
        [string]$Adapter
    )

    $main = switch ($Mode) {
        'Gemini36' { Test-Gemini36MainContent -Content $MainContent }
        'Gemini37' { Test-Gemini37MainContent -Content $MainContent }
        default { Test-StableMainContent -Content $MainContent }
    }
    if ([string]::IsNullOrWhiteSpace($Adapter) -and $main) {
        $stableMain = switch ($Mode) {
            'Gemini36' { ConvertFrom-Gemini36MainContent -Content $MainContent }
            'Gemini37' { ConvertFrom-Gemini37MainContent -Content $MainContent }
            default { $MainContent }
        }
        $Adapter = Resolve-StableAdapter -MainContent $stableMain
    }
    $workbench = Test-CompatibilityWorkbenchContent -Content $WorkbenchContent -Mode $Mode -Adapter $Adapter
    [pscustomobject]@{
        Main = $main
        Workbench = $workbench
        Extension = Test-RestartSafeExtensionContent -Content $ExtensionContent
        Adapter = $Adapter
    }
}

function Get-ExpectedCompatibilityHashes {
    param(
        [string]$MainHash,
        [string]$WorkbenchHash,
        [string]$ExtensionHash,
        [string]$AgentProSourceHash,
        [string]$AgentProCompatHash,
        [string]$ExtensionContent,
        [bool]$ExtensionStructure,
        [string]$ExpectedMainSha256,
        [string]$ExpectedWorkbenchSha256,
        [string]$ExpectedExtensionSha256,
        [string]$ExpectedBridgeSha256,
        [string]$ExpectedAgentProSourceSha256,
        [string]$ExpectedAgentProCompatSha256
    )

    if ([string]::IsNullOrWhiteSpace($ExpectedMainSha256)) { $ExpectedMainSha256 = $MainHash }
    if ([string]::IsNullOrWhiteSpace($ExpectedWorkbenchSha256)) { $ExpectedWorkbenchSha256 = $WorkbenchHash }
    if ([string]::IsNullOrWhiteSpace($ExpectedExtensionSha256)) {
        $ExpectedExtensionSha256 = if ($ExtensionStructure) {
            $ExtensionHash
        } else {
            Get-StringSha256 (ConvertTo-RestartSafeExtensionContent -Content $ExtensionContent)
        }
    }
    if ([string]::IsNullOrWhiteSpace($ExpectedBridgeSha256)) {
        $ExpectedBridgeSha256 = Get-Sha256 $script:OneLsBridgeSourcePath
    }
    if ([string]::IsNullOrWhiteSpace($ExpectedAgentProSourceSha256)) { $ExpectedAgentProSourceSha256 = $AgentProSourceHash }
    if ([string]::IsNullOrWhiteSpace($ExpectedAgentProCompatSha256)) { $ExpectedAgentProCompatSha256 = $AgentProCompatHash }
    [pscustomobject]@{
        Main = $ExpectedMainSha256
        Workbench = $ExpectedWorkbenchSha256
        Extension = $ExpectedExtensionSha256
        Bridge = $ExpectedBridgeSha256
        AgentProSource = $ExpectedAgentProSourceSha256
        AgentProCompat = $ExpectedAgentProCompatSha256
    }
}

function Get-NormalizedProductDate {
    param($Date)
    if ($Date -is [datetime]) { return $Date.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }
    [string]$Date
}

function New-CompatibilityStatusResult {
    param(
        [bool]$Passed,
        [string]$Mode,
        [string]$InstalledMode,
        $Files,
        $Hashes,
        [string]$Adapter,
        $Product,
        [string]$Date,
        $Checks,
        [string[]]$Failed
    )

    [pscustomobject]@{
        Passed = $Passed
        Mode = $Mode
        InstalledMode = $InstalledMode
        Root = $Files.Root
        MainSha256 = $Hashes.Main
        WorkbenchSha256 = $Hashes.Workbench
        ExtensionSha256 = $Hashes.Extension
        BridgeSha256 = $Hashes.Bridge
        AgentProSourceSha256 = $Hashes.AgentProSource
        AgentProCompatSha256 = $Hashes.AgentProCompat
        Adapter = $Adapter
        IdeVersion = $Product.ideVersion
        Date = $Date
        Checks = [pscustomobject]$Checks
        Message = if ($Passed) { "$Mode 模式静态检查通过。" } else { "当前尚未处于完整 $Mode 模式：$($Failed -join ', ')" }
    }
}

function Get-CompatibilityInstallStatus {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][ValidateSet('Stable', 'Gemini36', 'Gemini37')][string]$Mode,
        [string]$AgentProSourcePath,
        [string]$ExpectedMainSha256,
        [string]$ExpectedWorkbenchSha256,
        [string]$ExpectedExtensionSha256,
        [string]$ExpectedBridgeSha256,
        [string]$ExpectedAgentProSourceSha256,
        [string]$ExpectedAgentProCompatSha256,
        [string]$Adapter
    )

    try {
        $files = Get-InstallFiles -InstallRoot $InstallRoot -AgentProSourcePath $AgentProSourcePath
        Assert-InstallLayout $files
        $hashes = [pscustomobject]@{
            Main = Get-Sha256 $files.Main
            Workbench = Get-Sha256 $files.Workbench
            Extension = Get-Sha256 $files.Extension
            Bridge = Get-OptionalFileHash $files.Bridge
            AgentProSource = if ($null -eq $files.AgentProSource) { $null } else { Get-Sha256 $files.AgentProSource }
            AgentProCompat = if ($null -eq $files.AgentProCompat) { $null } else { Get-OptionalFileHash $files.AgentProCompat }
        }
        $mainContent = Get-Content -LiteralPath $files.Main -Raw
        $workbenchContent = Get-Content -LiteralPath $files.Workbench -Raw
        $extensionContent = Get-Content -LiteralPath $files.Extension -Raw
        $structure = Get-CompatibilityStructure -MainContent $mainContent -WorkbenchContent $workbenchContent -ExtensionContent $extensionContent -Mode $Mode -Adapter $Adapter
        $expected = Get-ExpectedCompatibilityHashes -MainHash $hashes.Main -WorkbenchHash $hashes.Workbench -ExtensionHash $hashes.Extension -AgentProSourceHash $hashes.AgentProSource -AgentProCompatHash $hashes.AgentProCompat -ExtensionContent $extensionContent -ExtensionStructure $structure.Extension -ExpectedMainSha256 $ExpectedMainSha256 -ExpectedWorkbenchSha256 $ExpectedWorkbenchSha256 -ExpectedExtensionSha256 $ExpectedExtensionSha256 -ExpectedBridgeSha256 $ExpectedBridgeSha256 -ExpectedAgentProSourceSha256 $ExpectedAgentProSourceSha256 -ExpectedAgentProCompatSha256 $ExpectedAgentProCompatSha256
        $product = Get-Content -LiteralPath $files.Product -Raw | ConvertFrom-Json
        $expectedChecksum = Get-WorkbenchChecksum $files.Workbench
        $actualChecksum = $product.checksums.PSObject.Properties['vs/workbench/workbench.desktop.main.js']?.Value
        $actualDate = Get-NormalizedProductDate $product.date
        $installedMode = Get-InstalledModeOrUnknown -MainContent $mainContent -WorkbenchContent $workbenchContent
        $defaultOverrideSafety = if ($Mode -eq 'Gemini37') {
            Test-Gemini37DefaultOverrideSafety -Content $mainContent
        } else {
            $true
        }
        $aliasModelCompatibility = if ($Mode -eq 'Gemini37') {
            Test-StableCatalogAliasCompatibility -Content $mainContent
        } else {
            $true
        }
        $agentProSourceStructure = if ($null -eq $files.AgentProSource) {
            $true
        } else {
            $agentProContent = [IO.File]::ReadAllText($files.AgentProSource)
            if ($Mode -eq 'Gemini37') {
                Test-Gemini37AgentProSourceContent -Content $agentProContent
            } else {
                -not ($agentProContent.Contains($script:Gemini37AgentProHelperName) -or $agentProContent.Contains('GEMINI37-MODEL-REWRITE'))
            }
        }
        $agentProCompatStructure = if ($null -eq $files.AgentProCompat) {
            $true
        } elseif ($Mode -eq 'Gemini37') {
            Test-Path -LiteralPath $files.AgentProCompat -PathType Leaf
        } else {
            -not (Test-Path -LiteralPath $files.AgentProCompat)
        }
        $checks = [ordered]@{
            MainHash = $hashes.Main -eq $expected.Main
            WorkbenchHash = $hashes.Workbench -eq $expected.Workbench
            ExtensionHash = $hashes.Extension -eq $expected.Extension
            BridgeHash = $hashes.Bridge -eq $expected.Bridge
            AgentProSourceHash = $null -eq $files.AgentProSource -or $hashes.AgentProSource -eq $expected.AgentProSource
            AgentProCompatHash = $null -eq $files.AgentProCompat -or
                ($null -eq $hashes.AgentProCompat -and [string]::IsNullOrWhiteSpace($expected.AgentProCompat)) -or
                $hashes.AgentProCompat -eq $expected.AgentProCompat
            MainStructure = $structure.Main
            DefaultOverrideSafety = $defaultOverrideSafety
            AliasModelCompatibility = $aliasModelCompatibility
            WorkbenchStructure = $structure.Workbench
            ExtensionStructure = $structure.Extension
            AgentProSourceStructure = $agentProSourceStructure
            AgentProCompatStructure = $agentProCompatStructure
            IdeVersion = $product.ideVersion -eq $script:StableIdeVersion
            Date = $actualDate -eq $script:StableDate
            WorkbenchChecksum = $actualChecksum -eq $expectedChecksum
        }
        $failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object Key)
        $passed = $failed.Count -eq 0
        New-CompatibilityStatusResult -Passed $passed -Mode $Mode -InstalledMode $installedMode -Files $files -Hashes $hashes -Adapter $structure.Adapter -Product $product -Date $actualDate -Checks $checks -Failed $failed
    } catch {
        [pscustomobject]@{ Passed = $false; Mode = $Mode; Root = $InstallRoot; Message = $_.Exception.Message }
    }
}

function Get-StableInstallStatus {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [string]$ExpectedMainSha256,
        [string]$ExpectedWorkbenchSha256,
        [string]$ExpectedExtensionSha256,
        [string]$ExpectedBridgeSha256,
        [string]$AgentProSourcePath,
        [string]$ExpectedAgentProSourceSha256,
        [string]$ExpectedAgentProCompatSha256,
        [string]$Adapter
    )

    Get-CompatibilityInstallStatus @PSBoundParameters -Mode Stable
}

function Assert-CompatibilitySourceAllowed {
    param($Source, [string]$PreviousMode, [switch]$AllowAdaptive)
    if (-not $AllowAdaptive -and $Source.Main -notin @($script:RawMainSha256, $script:StableMainSha256, $script:LegacyStableMainSha256)) {
        throw "未知 main.js 哈希，拒绝修改：$($Source.Main)"
    }
    if (-not $AllowAdaptive -and $Source.Workbench -notin @($script:RawWorkbenchSha256, $script:StableWorkbenchSha256)) {
        throw "未知 workbench 哈希，拒绝修改：$($Source.Workbench)"
    }
}

function Assert-CompatibilityCandidateAllowed {
    param($Target, [string]$Mode, [switch]$AllowAdaptive)
    if (-not $AllowAdaptive -and $Mode -eq 'Stable' -and $Target.Main -ne $script:StableMainSha256) {
        throw 'main.js 候选哈希不符合已验证档案。'
    }
    if (-not $AllowAdaptive -and $Mode -eq 'Stable' -and $Target.Workbench -ne $script:StableWorkbenchSha256) {
        throw 'workbench 候选哈希不符合已验证档案。'
    }
}

function New-CompatibilityInstallResult {
    param(
        [string]$Mode,
        [string]$PreviousMode,
        [bool]$Changed,
        $Backup,
        [string]$Message,
        $Source,
        $Target,
        [string]$Adapter,
        $Status
    )

    [pscustomobject]@{
        Passed = $true
        Mode = $Mode
        PreviousMode = $PreviousMode
        Changed = $Changed
        Backup = $Backup
        Message = $Message
        SourceMainSha256 = $Source.Main
        SourceWorkbenchSha256 = $Source.Workbench
        SourceExtensionSha256 = $Source.Extension
        SourceBridgeSha256 = $Source.Bridge
        SourceAgentProSha256 = $Source.AgentProSource
        SourceAgentProCompatSha256 = $Source.AgentProCompat
        TargetMainSha256 = $Target.Main
        TargetWorkbenchSha256 = $Target.Workbench
        TargetExtensionSha256 = $Target.Extension
        TargetBridgeSha256 = $Target.Bridge
        TargetAgentProSha256 = $Target.AgentProSource
        TargetAgentProCompatSha256 = $Target.AgentProCompat
        Adapter = $Adapter
        Status = $Status
    }
}

function Set-CompatibilityMode {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$BackupRoot,
        [Parameter(Mandatory)][ValidateSet('Stable', 'Gemini36', 'Gemini37')][string]$Mode,
        [string]$AgentProSourcePath,
        [switch]$ClearModelCache,
        [switch]$AllowAdaptive,
        [switch]$StopRunningProcesses
    )

    $files = Get-InstallFiles -InstallRoot $InstallRoot -AgentProSourcePath $AgentProSourcePath
    Assert-InstallLayout $files
    if (-not (Test-Path -LiteralPath $script:OneLsBridgeSourcePath -PathType Leaf)) { throw "缺少 OneLS 桥接源文件：$script:OneLsBridgeSourcePath" }
    if ($Mode -eq 'Gemini37' -and $null -ne $files.AgentProSource -and
        -not (Test-Path -LiteralPath $script:Gemini37AgentProHelperSourcePath -PathType Leaf)) {
        throw "缺少 Gemini 3.7 Agent Pro helper：$script:Gemini37AgentProHelperSourcePath"
    }
    if ($StopRunningProcesses) {
        Stop-ScopedAntigravityProcesses -InstallRoot $files.Root
    } else {
        Assert-NoAntigravityProcesses -InstallRoot $files.Root
    }
    $source = [pscustomobject]@{
        Main = Get-Sha256 $files.Main
        Workbench = Get-Sha256 $files.Workbench
        Extension = Get-Sha256 $files.Extension
        Bridge = Get-OptionalFileHash $files.Bridge
        AgentProSource = if ($null -eq $files.AgentProSource) { $null } else { Get-Sha256 $files.AgentProSource }
        AgentProCompat = if ($null -eq $files.AgentProCompat) { $null } else { Get-OptionalFileHash $files.AgentProCompat }
    }
    $mainContent = Get-Content -LiteralPath $files.Main -Raw
    $workbenchContent = Get-Content -LiteralPath $files.Workbench -Raw
    $extensionContent = Get-Content -LiteralPath $files.Extension -Raw
    $agentProContent = if ($null -eq $files.AgentProSource) { $null } else { [IO.File]::ReadAllText($files.AgentProSource) }
    $previousMode = Get-InstalledModeOrUnknown -MainContent $mainContent -WorkbenchContent $workbenchContent
    Assert-CompatibilitySourceAllowed -Source $source -PreviousMode $previousMode -AllowAdaptive:$AllowAdaptive

    $targetBridgeHash = Get-Sha256 $script:OneLsBridgeSourcePath
    $targetAgentProContent = if ($null -eq $agentProContent) {
        $null
    } elseif ($Mode -eq 'Gemini37') {
        ConvertTo-Gemini37AgentProSourceContent -Content $agentProContent
    } else {
        ConvertTo-StableAgentProSourceContent -Content $agentProContent
    }
    $targetAgentProHash = if ($null -eq $targetAgentProContent) { $null } else { Get-StringSha256 $targetAgentProContent }
    $targetAgentProCompatHash = if ($Mode -eq 'Gemini37' -and $null -ne $files.AgentProCompat) {
        Get-Sha256 $script:Gemini37AgentProHelperSourcePath
    } else {
        $null
    }
    $currentStatus = Get-CompatibilityInstallStatus -InstallRoot $InstallRoot -Mode $Mode -AgentProSourcePath $files.AgentProSource -ExpectedBridgeSha256 $targetBridgeHash -ExpectedAgentProSourceSha256 $targetAgentProHash -ExpectedAgentProCompatSha256 $targetAgentProCompatHash
    if ($currentStatus.Passed) {
        $unchangedTarget = [pscustomobject]@{ Main = $source.Main; Workbench = $source.Workbench; Extension = $source.Extension; Bridge = $targetBridgeHash; AgentProSource = $targetAgentProHash; AgentProCompat = $targetAgentProCompatHash }
        return New-CompatibilityInstallResult -Mode $Mode -PreviousMode $previousMode -Changed $false -Backup $null -Message "$Mode 模式已是健康状态，无需修改。" -Source $source -Target $unchangedTarget -Adapter $currentStatus.Adapter -Status $currentStatus
    }

    $candidate = Get-CompatibilityCandidate `
        -MainContent $mainContent `
        -WorkbenchContent $workbenchContent `
        -ExtensionContent $extensionContent `
        -Mode $Mode
    $main = $candidate.Main
    $workbench = $candidate.Workbench
    $extension = $candidate.Extension
    $adapter = $candidate.Adapter
    $target = [pscustomobject]@{
        Main = Get-StringSha256 $main
        Workbench = Get-StringSha256 $workbench
        Extension = Get-StringSha256 $extension
        Bridge = $targetBridgeHash
        AgentProSource = $targetAgentProHash
        AgentProCompat = $targetAgentProCompatHash
    }
    Assert-CompatibilityCandidateAllowed -Target $target -Mode $Mode -AllowAdaptive:$AllowAdaptive

    Test-JavaScriptSyntax -Content $main -Name 'main.js'
    Test-JavaScriptSyntax -Content $workbench -Name 'workbench'
    Test-JavaScriptSyntax -Content $extension -Name 'extension.js'
    Test-JavaScriptSyntax -Content ([IO.File]::ReadAllText($script:OneLsBridgeSourcePath)) -Name 'OneLS bridge'
    if ($null -ne $targetAgentProContent) { Test-JavaScriptSyntax -Content $targetAgentProContent -Name 'Agent Pro source.js' }
    if ($Mode -eq 'Gemini37' -and $null -ne $files.AgentProCompat) {
        Test-JavaScriptSyntax -Content ([IO.File]::ReadAllText($script:Gemini37AgentProHelperSourcePath)) -Name 'Gemini 3.7 Agent Pro helper'
    }

    $backup = New-StableBackup -Files $files -BackupRoot $BackupRoot -IncludeModelCache:$ClearModelCache
    try {
        Write-Utf8Atomic $files.Main $main
        Write-Utf8Atomic $files.Workbench $workbench
        Write-Utf8Atomic $files.Extension $extension
        Copy-FileAtomic -Source $script:OneLsBridgeSourcePath -Destination $files.Bridge
        if ($null -ne $files.AgentProSource) {
            Write-Utf8Atomic $files.AgentProSource $targetAgentProContent
            if ($Mode -eq 'Gemini37') {
                Copy-FileAtomic -Source $script:Gemini37AgentProHelperSourcePath -Destination $files.AgentProCompat
            } else {
                Remove-Item -LiteralPath $files.AgentProCompat -Force -ErrorAction SilentlyContinue
            }
        }
        Update-StableProduct $files.Product $files.Workbench
        $cacheMessage = if ($ClearModelCache) { Clear-StableModelCache } else { '未清理模型缓存。' }
        $status = Get-CompatibilityInstallStatus -InstallRoot $InstallRoot -Mode $Mode -AgentProSourcePath $files.AgentProSource -ExpectedMainSha256 $target.Main -ExpectedWorkbenchSha256 $target.Workbench -ExpectedExtensionSha256 $target.Extension -ExpectedBridgeSha256 $target.Bridge -ExpectedAgentProSourceSha256 $target.AgentProSource -ExpectedAgentProCompatSha256 $target.AgentProCompat -Adapter $adapter
        if (-not $status.Passed) { throw $status.Message }
        New-CompatibilityInstallResult -Mode $Mode -PreviousMode $previousMode -Changed $true -Backup $backup -Message "$Mode 模式已应用。$cacheMessage" -Source $source -Target $target -Adapter $adapter -Status $status
    } catch {
        Restore-StableBackup -BackupDirectory $backup | Out-Null
        throw
    }
}

function Set-StableMode {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$BackupRoot,
        [string]$AgentProSourcePath,
        [switch]$ClearModelCache,
        [switch]$AllowAdaptive,
        [switch]$StopRunningProcesses
    )

    Set-CompatibilityMode @PSBoundParameters -Mode Stable
}

function Get-LatestStableBackup {
    param([Parameter(Mandatory)][string]$BackupRoot)
    Get-ChildItem -LiteralPath $BackupRoot -Directory -Filter 'stable-*' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

Export-ModuleMember -Function @(
    'Clear-StableModelCache',
    'ConvertTo-Gemini37AgentProSourceContent',
    'ConvertTo-Gemini36MainContent',
    'ConvertTo-Gemini36WorkbenchContent',
    'ConvertTo-Gemini37MainContent',
    'ConvertTo-Gemini37WorkbenchContent',
    'ConvertTo-RestartSafeExtensionContent',
    'ConvertTo-StableAgentProSourceContent',
    'ConvertTo-StableMainContent',
    'ConvertTo-StableWorkbenchContent',
    'Find-AntigravityInstallRoots',
    'Find-AgentProSourcePath',
    'Get-CompatibilityInstallStatus',
    'Get-InstalledCompatibilityMode',
    'Get-LatestStableBackup',
    'Get-StableInstallStatus',
    'Restore-StableBackup',
    'Set-CompatibilityMode',
    'Set-StableMode',
    'Test-Gemini36MainContent',
    'Test-Gemini36WorkbenchContent',
    'Test-Gemini37MainContent',
    'Test-Gemini37AgentProSourceContent',
    'Test-Gemini37WorkbenchContent',
    'Test-RestartSafeExtensionContent',
    'Test-StableMainContent',
    'Test-StableWorkbenchContent'
)

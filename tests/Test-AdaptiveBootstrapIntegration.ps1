$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = Split-Path $PSScriptRoot -Parent
$modulePath = Join-Path $projectRoot 'scripts\StableMode.Core.psm1'
$bootstrap = Join-Path $projectRoot 'StableBootstrap.ps1'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntigravityBootstrapTest-' + [guid]::NewGuid().ToString('N'))
$installRoot = Join-Path $temporaryRoot 'install'
$stateRoot = Join-Path $temporaryRoot 'state'
$profilePath = Join-Path $stateRoot 'profiles\local-generated.json'
$settingsPath = Join-Path $stateRoot 'config\bootstrap-settings.json'
$agentProSourcePath = Join-Path $temporaryRoot 'agent-pro\vendor\bundled-origin\source.js'
$originalAgentProSourceOverride = $env:ANTIGRAVITY_AGENT_PRO_SOURCE
Import-Module $modulePath -Force

function Write-JsonFile {
    param([string]$Path, $Value)
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($Path)) -Force | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
}

function New-InstallFixture {
    $rawMain = @'
class MainFixture {
    async pushUpdate(t){if(!Object.hasOwn(UGe,t.topicName))throw new Error(`Invalid topic: ${t.topicName}`);const r=t.appliedUpdate;return r}
    async start(){const f={httpsPort:1},a='token';await this.a.initialize(f.httpsPort,a)}
}
const b=[],f={httpsPort:1,httpPort:2},a='token';let y;
y={host:"127.0.0.1",resource:"",port:f.httpsPort,csrfToken:a,homeDir:sUs()};b.some(v=>v.port===f.httpsPort&&v.csrfToken===a);
'@
    $rawWorkbench = @'
class WorkbenchFixture {
    get baseUrl(){return`https://127.0.0.1:${this.port}`}
    qb(e){if(e.choice.case!=="model")return;const i=Jku(e.choice.value);this.db.pushUpdate(i)}
    async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}
}
function mUc(t){let e=Hi(GMt);return t?.modelAlias?e.choice={case:"alias",value:t.modelAlias}:t?.value&&(e.choice={case:"model",value:t.value}),e}
const Qun=t=>{if(!t.modelOrAlias)return null;let e=t.modelOrAlias.choice.case==="model"?t.modelOrAlias.choice.value:oz.UNSPECIFIED,i=t.modelOrAlias.choice.case==="alias"?t.modelOrAlias.choice.value:void 0;return{label:t.label,value:e};};
const requestFixture={requestedModel:this.m,customModelInfoOverride:this.n};
'@
    $rawExtension = 'k.MetadataProvider.initialize(e),i.end(),f.UserStatusUpdater.getInstance().restartUpdateLoop(),i=l.JetskiTrace.task("extension activate: sentry init"),U.ElectronMainLsClient.initialize(e),W.LanguageServerClient.initialize(),await W.LanguageServerClient.getInstance().initAsync(),e.subscriptions.push(W.LanguageServerClient.getInstance()),i.end(),i=l.JetskiTrace.task("extension activate: unleash init")'
    $main = ConvertTo-StableMainContent -Content $rawMain
    $workbench = ConvertTo-StableWorkbenchContent -Content $rawWorkbench -Adapter 'legacy-http-v1'
    $extension = ConvertTo-RestartSafeExtensionContent -Content $rawExtension
    $paths = [ordered]@{
        Main = Join-Path $installRoot 'resources\app\out\main.js'
        Workbench = Join-Path $installRoot 'resources\app\out\vs\workbench\workbench.desktop.main.js'
        Product = Join-Path $installRoot 'resources\app\product.json'
        Extension = Join-Path $installRoot 'resources\app\extensions\antigravity\dist\extension.js'
        Bridge = Join-Path $installRoot 'resources\app\dao-one-ls-agent-pro.cjs'
        AgentProSource = $agentProSourcePath
        AgentProCompat = Join-Path ([IO.Path]::GetDirectoryName($agentProSourcePath)) '_ag-gemini37-compat.cjs'
    }
    foreach ($path in $paths.Values) { New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($path)) -Force | Out-Null }
    New-Item -ItemType File -Path (Join-Path $installRoot 'Antigravity.exe') -Force | Out-Null
    [IO.File]::WriteAllText($paths.Main, $main, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($paths.Workbench, $workbench, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($paths.Extension, $extension, [Text.UTF8Encoding]::new($false))
    $agentProSource = @'
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
    [IO.File]::WriteAllText($paths.AgentProSource, $agentProSource, [Text.UTF8Encoding]::new($false))
    Copy-Item -LiteralPath (Join-Path $projectRoot 'runtime\OneLSAgentProxyBridge.cjs') -Destination $paths.Bridge
    $workbenchHash = (Get-FileHash -LiteralPath $paths.Workbench -Algorithm SHA256).Hash
    $checksum = [Convert]::ToBase64String([Convert]::FromHexString($workbenchHash)).TrimEnd('=')
    Write-JsonFile $paths.Product ([pscustomobject]@{
        ideVersion = '2.5.5'
        date = '2026-08-13T08:28:19.366Z'
        checksums = [pscustomobject]@{ 'vs/workbench/workbench.desktop.main.js' = $checksum }
    })
    [pscustomobject]$paths
}

function Get-HashPair {
    param($Paths)
    [pscustomobject]@{
        Main = (Get-FileHash -LiteralPath $Paths.Main -Algorithm SHA256).Hash
        Workbench = (Get-FileHash -LiteralPath $Paths.Workbench -Algorithm SHA256).Hash
        Extension = (Get-FileHash -LiteralPath $Paths.Extension -Algorithm SHA256).Hash
        Bridge = (Get-FileHash -LiteralPath $Paths.Bridge -Algorithm SHA256).Hash
        AgentProSource = (Get-FileHash -LiteralPath $Paths.AgentProSource -Algorithm SHA256).Hash
        AgentProCompat = if (Test-Path -LiteralPath $Paths.AgentProCompat -PathType Leaf) { (Get-FileHash -LiteralPath $Paths.AgentProCompat -Algorithm SHA256).Hash } else { $null }
    }
}

function Update-WorkbenchChecksum {
    param($Paths)
    $product = Get-Content -LiteralPath $Paths.Product -Raw | ConvertFrom-Json
    $workbenchHash = (Get-FileHash -LiteralPath $Paths.Workbench -Algorithm SHA256).Hash
    $product.checksums.'vs/workbench/workbench.desktop.main.js' =
        [Convert]::ToBase64String([Convert]::FromHexString($workbenchHash)).TrimEnd('=')
    Write-JsonFile $Paths.Product $product
}

function Invoke-Bootstrap {
    param([string]$Mode, [switch]$SuppressOutput)
    $arguments = @('-NoProfile', '-File', $bootstrap, '-InstallRoot', $installRoot, '-StateRoot', $stateRoot, '-NoLaunch', '-SkipModelCache')
    if (-not [string]::IsNullOrWhiteSpace($Mode)) { $arguments += @('-Mode', $Mode) }
    if ($SuppressOutput) {
        & pwsh @arguments *> $null
    } else {
        & pwsh @arguments
    }
    $LASTEXITCODE
}

try {
    $paths = New-InstallFixture
    $env:ANTIGRAVITY_AGENT_PRO_SOURCE = $paths.AgentProSource
    $stablePair = Get-HashPair $paths
    Write-JsonFile $settingsPath ([pscustomobject]@{ installRoot = $installRoot })
    Write-JsonFile $profilePath ([pscustomobject]@{
        createdUtc = '2026-07-23T00:00:00Z'
        sourceMainSha256 = $stablePair.Main
        sourceWorkbenchSha256 = $stablePair.Workbench
        targetMainSha256 = $stablePair.Main
        targetWorkbenchSha256 = $stablePair.Workbench
        targetExtensionSha256 = $stablePair.Extension
        adapter = 'legacy-http-v1'
    })

    if ((Invoke-Bootstrap) -ne 0) { throw '旧配置默认 Stable 迁移失败。' }
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    if ($settings.selectedMode -ne 'Stable' -or $settings.lastSuccessfulMode -ne 'Stable') { throw '旧 settings 未迁移为 Stable。' }
    $profiles = @(Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json)
    $stableProfile = @($profiles | Where-Object mode -eq 'Stable')[0]
    if ($stableProfile.schemaVersion -ne 8 -or $stableProfile.patchVersion -ne 'compatibility-v13-gemini37-real-route-gemini36') { throw '旧 Stable 档案未迁移到当前组合策略。' }
    if ([string]::IsNullOrWhiteSpace($stableProfile.targetBridgeSha256)) { throw '旧 Stable 档案未补桥哈希。' }

    if ((Invoke-Bootstrap 'Gemini37') -ne 0) { throw '显式 Gemini37 应用失败。' }
    if ((Get-InstalledCompatibilityMode -InstallRoot $installRoot) -ne 'Gemini37') { throw 'Bootstrap 未进入 Gemini37。' }
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    if ($settings.selectedMode -ne 'Gemini37' -or $settings.lastSuccessfulMode -ne 'Gemini37') { throw 'Gemini37 模式未持久化。' }
    $profiles = @(Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json)
    if (@($profiles | Where-Object mode -eq 'Stable').Count -lt 1 -or @($profiles | Where-Object mode -eq 'Gemini37').Count -ne 1) { throw 'Stable 与 Gemini37 档案未并存。' }
    $geminiProfile = @($profiles | Where-Object mode -eq 'Gemini37')[0]
    if ($geminiProfile.schemaVersion -ne 8 -or $geminiProfile.patchVersion -ne 'compatibility-v13-gemini37-real-route-gemini36') { throw 'Gemini37 档案版本错误。' }
    if ([string]::IsNullOrWhiteSpace($geminiProfile.targetAgentProSha256) -or [string]::IsNullOrWhiteSpace($geminiProfile.targetAgentProCompatSha256)) { throw 'Gemini37 档案缺少 Agent Pro 路由哈希。' }
    $geminiTarget = $geminiProfile.targetMainSha256
    $main = [IO.File]::ReadAllText($paths.Main)
    if (-not $main.Contains('Gemini 3.7 Flash') -or -not $main.Contains('Gemini 3.6 Flash')) { throw '组合名单未同时保留 3.7 与 3.6。' }
    if (-not (Test-Gemini37AgentProSourceContent -Content ([IO.File]::ReadAllText($paths.AgentProSource)))) { throw 'Bootstrap 未部署 Agent Pro 真实 3.7 路由补丁。' }
    if (-not (Test-Path -LiteralPath $paths.AgentProCompat -PathType Leaf)) { throw 'Bootstrap 未部署 Agent Pro helper。' }

    $backupCount = @(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'backups') -Directory).Count
    if ((Invoke-Bootstrap) -ne 0) { throw '无参数复用 Gemini37 失败。' }
    if ((Get-InstalledCompatibilityMode -InstallRoot $installRoot) -ne 'Gemini37') { throw '无参数启动未保持 Gemini37。' }
    if (@(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'backups') -Directory).Count -ne $backupCount) { throw '健康 Gemini37 快速路径不应新增备份。' }

    if ((Invoke-Bootstrap 'Stable') -ne 0) { throw '显式回退 Stable 失败。' }
    if ((Get-InstalledCompatibilityMode -InstallRoot $installRoot) -ne 'Stable') { throw 'Bootstrap 未回退 Stable。' }
    if (([IO.File]::ReadAllText($paths.AgentProSource)).Contains('GEMINI37-MODEL-REWRITE') -or (Test-Path -LiteralPath $paths.AgentProCompat)) { throw 'Stable 回退未清理 Agent Pro 3.7 路由补丁。' }
    $profiles = @(Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json)
    if (@($profiles | Where-Object mode -eq 'Gemini37')[0].targetMainSha256 -ne $geminiTarget) { throw 'Stable 回退覆盖了 Gemini37 档案。' }

    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $settings.selectedMode = 'BrokenMode'
    Write-JsonFile $settingsPath $settings
    $beforeInvalid = Get-HashPair $paths
    $profileBytes = [IO.File]::ReadAllBytes($profilePath)
    $backupCount = @(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'backups') -Directory).Count
    if ((Invoke-Bootstrap -SuppressOutput) -eq 0) { throw '非法持久模式必须 fail-closed。' }
    $afterInvalid = Get-HashPair $paths
    if (($beforeInvalid | ConvertTo-Json -Compress) -ne ($afterInvalid | ConvertTo-Json -Compress)) { throw '非法模式修改了 IDE 文件。' }
    if (@(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'backups') -Directory).Count -ne $backupCount) { throw '非法模式创建了备份。' }
    if ([Convert]::ToHexString($profileBytes) -ne [Convert]::ToHexString([IO.File]::ReadAllBytes($profilePath))) { throw '非法模式修改了档案。' }

    $settings.selectedMode = 'Stable'
    Write-JsonFile $settingsPath $settings
    $profileCountBeforeRepair = @(Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json).Count
    $product = Get-Content -LiteralPath $paths.Product -Raw | ConvertFrom-Json
    $product.ideVersion = '0.0.0-corrupt'
    Write-JsonFile $paths.Product $product
    $backupCount = @(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'backups') -Directory).Count
    if ((Invoke-Bootstrap) -ne 0) { throw 'Stable 产品状态自愈失败。' }
    if (@(Get-ChildItem -LiteralPath (Join-Path $stateRoot 'backups') -Directory).Count -ne ($backupCount + 1)) { throw '产品漂移应新增一次备份。' }
    if ((Get-Content -LiteralPath $paths.Product -Raw | ConvertFrom-Json).ideVersion -ne '2.5.5') { throw '产品版本漂移未修复。' }
    if (@(Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json).Count -ne $profileCountBeforeRepair) { throw '产品漂移修复不应重复注册相同模式档案。' }

    Write-Output 'PASS: Gemini37 persistence, cross-mode profiles, invalid fail-closed, and product repair'
}
finally {
    $env:ANTIGRAVITY_AGENT_PRO_SOURCE = $originalAgentProSourceOverride
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}

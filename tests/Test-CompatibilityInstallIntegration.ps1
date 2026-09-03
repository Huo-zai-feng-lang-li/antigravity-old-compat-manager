$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot '..\scripts\StableMode.Core.psm1') -Force

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntigravityCompatibilityTest-' + [guid]::NewGuid().ToString('N'))
$installRoot = Join-Path $temporaryRoot 'install'
$backupRoot = Join-Path $temporaryRoot 'backups'
$agentProSourcePath = Join-Path $temporaryRoot 'agent-pro\vendor\bundled-origin\source.js'

function New-InstallFixture {
    param([string]$Destination)

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
const requestFixture={requestedModel:this.m,customModelInfoOverride:this.n};
'@
    $rawExtension = 'k.MetadataProvider.initialize(e),i.end(),f.UserStatusUpdater.getInstance().restartUpdateLoop(),i=l.JetskiTrace.task("extension activate: sentry init"),U.ElectronMainLsClient.initialize(e),W.LanguageServerClient.initialize(),await W.LanguageServerClient.getInstance().initAsync(),e.subscriptions.push(W.LanguageServerClient.getInstance()),i.end(),i=l.JetskiTrace.task("extension activate: unleash init")'
    $main = ConvertTo-StableMainContent -Content $rawMain
    $workbench = ConvertTo-StableWorkbenchContent -Content $rawWorkbench -Adapter 'legacy-http-v1'
    $extension = ConvertTo-RestartSafeExtensionContent -Content $rawExtension
    $mainPath = Join-Path $Destination 'resources\app\out\main.js'
    $workbenchPath = Join-Path $Destination 'resources\app\out\vs\workbench\workbench.desktop.main.js'
    $productPath = Join-Path $Destination 'resources\app\product.json'
    $extensionPath = Join-Path $Destination 'resources\app\extensions\antigravity\dist\extension.js'
    $bridgePath = Join-Path $Destination 'resources\app\dao-one-ls-agent-pro.cjs'
    foreach ($path in @($mainPath, $workbenchPath, $productPath, $extensionPath, $bridgePath)) {
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($path)) -Force | Out-Null
    }
    New-Item -ItemType File -Path (Join-Path $Destination 'Antigravity.exe') -Force | Out-Null
    [IO.File]::WriteAllText($mainPath, $main, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($workbenchPath, $workbench, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($extensionPath, $extension, [Text.UTF8Encoding]::new($false))
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\runtime\OneLSAgentProxyBridge.cjs') -Destination $bridgePath
    $checksum = [Convert]::ToBase64String([Convert]::FromHexString((Get-FileHash -LiteralPath $workbenchPath -Algorithm SHA256).Hash)).TrimEnd('=')
    $product = [pscustomobject]@{
        ideVersion = '2.5.5'
        date = '2026-08-13T08:28:19.366Z'
        checksums = [pscustomobject]@{ 'vs/workbench/workbench.desktop.main.js' = $checksum }
    }
    [IO.File]::WriteAllText($productPath, ($product | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
}

function Get-InstallHash {
    param([string]$RelativePath)
    (Get-FileHash -LiteralPath (Join-Path $installRoot $RelativePath) -Algorithm SHA256).Hash
}

try {
    New-InstallFixture -Destination $installRoot
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($agentProSourcePath)) -Force | Out-Null
    $agentProOriginal = @'
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
    [IO.File]::WriteAllText($agentProSourcePath, $agentProOriginal, [Text.UTF8Encoding]::new($false))
    $agentProCompatPath = Join-Path ([IO.Path]::GetDirectoryName($agentProSourcePath)) '_ag-gemini37-compat.cjs'
    $mainRelative = 'resources\app\out\main.js'
    $workbenchRelative = 'resources\app\out\vs\workbench\workbench.desktop.main.js'
    $extensionRelative = 'resources\app\extensions\antigravity\dist\extension.js'
    $bridgeRelative = 'resources\app\dao-one-ls-agent-pro.cjs'
    $stableHashes = @{
        Main = Get-InstallHash $mainRelative
        Workbench = Get-InstallHash $workbenchRelative
        Extension = Get-InstallHash $extensionRelative
        Bridge = Get-InstallHash $bridgeRelative
    }

    Write-Host 'STEP 1: verify stable baseline'
    $initial = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Stable -AllowAdaptive
    if (-not $initial.Passed -or $initial.Mode -ne 'Stable') { throw '稳定模式基线检查失败。' }
    if ($initial.Changed -or $null -ne $initial.Backup) { throw "健康稳定模式必须零修改、零备份：$($initial | ConvertTo-Json -Depth 8 -Compress)" }

    Write-Host 'STEP 1A: migrate legacy Stable catalog'
    $stableMainContent = [IO.File]::ReadAllText((Join-Path $installRoot $mainRelative))
    $currentStableAllowlist = '["Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]'
    $legacyStableAllowlist = '["Gemini 3.5 Flash (High)","Gemini 3.5 Flash (Medium)","Gemini 3.5 Flash (Low)","Claude Sonnet 4.6 (Thinking)","Claude Opus 4.6 (Thinking)"]'
    $legacyStableMain = $stableMainContent.Replace($currentStableAllowlist, $legacyStableAllowlist, [StringComparison]::Ordinal)
    if ($legacyStableMain -eq $stableMainContent) { throw '旧 Stable 测试夹具未命中名单锚点。' }
    [IO.File]::WriteAllText((Join-Path $installRoot $mainRelative), $legacyStableMain, [Text.UTF8Encoding]::new($false))
    $legacyUpgrade = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Stable -AllowAdaptive
    if (-not $legacyUpgrade.Passed -or -not $legacyUpgrade.Changed -or $legacyUpgrade.PreviousMode -ne 'Stable') { throw '旧 Stable 名单升级结果错误。' }
    if ((Get-InstallHash $mainRelative) -ne $stableHashes.Main) { throw '旧 Stable 未升级为仅 Claude 名单。' }

    Write-Host 'STEP 2: switch Stable to Gemini36'
    $gemini = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Gemini36 -AllowAdaptive
    if (-not $gemini.Passed -or $gemini.Mode -ne 'Gemini36' -or $gemini.PreviousMode -ne 'Stable') { throw 'Stable 到 Gemini36 切换结果错误。' }
    if (-not $gemini.Changed -or -not (Test-Path -LiteralPath $gemini.Backup)) { throw '首次 Gemini36 切换必须修改并备份。' }
    if ((Get-InstalledCompatibilityMode -InstallRoot $installRoot) -ne 'Gemini36') { throw '安装目录未进入 Gemini36。' }
    $geminiStatus = Get-CompatibilityInstallStatus -InstallRoot $installRoot -Mode Gemini36
    if (-not $geminiStatus.Passed) { throw "Gemini36 静态复验失败：$($geminiStatus.Message)" }
    if ((Get-InstallHash $extensionRelative) -ne $stableHashes.Extension) { throw 'Gemini36 不得破坏登录重启补丁。' }
    if ((Get-InstallHash $bridgeRelative) -ne $stableHashes.Bridge) { throw 'Gemini36 不得破坏 Agent Pro OneLS 桥。' }

    $geminiWorkbenchContent = [IO.File]::ReadAllText((Join-Path $installRoot $workbenchRelative))
    Write-Host 'STEP 2A: reject mixed Gemini36 generations through Set path'
    $mixedWorkbenchContent = $geminiWorkbenchContent.Replace('_agGemini36Ids=new Set([1264,1265])', '_agGemini36Ids=new Set([1264,1265,1266])', [StringComparison]::Ordinal)
    if ($mixedWorkbenchContent -eq $geminiWorkbenchContent) { throw '混合代际测试夹具未命中 ID 锚点。' }
    [IO.File]::WriteAllText((Join-Path $installRoot $workbenchRelative), $mixedWorkbenchContent, [Text.UTF8Encoding]::new($false))
    $mixedMainHash = Get-InstallHash $mainRelative
    $mixedWorkbenchHash = Get-InstallHash $workbenchRelative
    $mixedBackupCount = @(Get-ChildItem -LiteralPath $backupRoot -Directory).Count
    $mixedRejected = $false
    try {
        Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Gemini36 -AllowAdaptive | Out-Null
    } catch {
        $mixedRejected = $_.Exception.Message -like '*补丁代际不一致*'
    }
    if (-not $mixedRejected) { throw 'Set 路径未拒绝新旧 Gemini36 混合结构。' }
    if ((Get-InstallHash $mainRelative) -ne $mixedMainHash -or (Get-InstallHash $workbenchRelative) -ne $mixedWorkbenchHash) { throw '混合代际拒绝后文件发生变化。' }
    if (@(Get-ChildItem -LiteralPath $backupRoot -Directory).Count -ne $mixedBackupCount) { throw '混合代际拒绝不应创建备份。' }
    [IO.File]::WriteAllText((Join-Path $installRoot $workbenchRelative), $geminiWorkbenchContent, [Text.UTF8Encoding]::new($false))

    $brokenTransport = $geminiWorkbenchContent.Replace('http://127.0.0.1:${this.port}', 'https://127.0.0.1:${this.port}')
    if ($brokenTransport -eq $geminiWorkbenchContent) { throw '测试夹具未命中 OneLS 传输锚点。' }
    [IO.File]::WriteAllText((Join-Path $installRoot $workbenchRelative), $brokenTransport, [Text.UTF8Encoding]::new($false))
    $brokenStatus = Get-CompatibilityInstallStatus -InstallRoot $installRoot -Mode Gemini36
    if ($brokenStatus.Checks.WorkbenchStructure) { throw 'Gemini36 健康检查漏检底层 OneLS 传输损坏。' }
    [IO.File]::WriteAllText((Join-Path $installRoot $workbenchRelative), $geminiWorkbenchContent, [Text.UTF8Encoding]::new($false))

    $backupCount = @(Get-ChildItem -LiteralPath $backupRoot -Directory).Count
    Write-Host 'STEP 3: verify Gemini36 idempotency'
    $secondGemini = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Gemini36 -AllowAdaptive
    if ($secondGemini.Changed -or $null -ne $secondGemini.Backup) { throw '重复 Gemini36 应用必须零修改、零备份。' }
    if (@(Get-ChildItem -LiteralPath $backupRoot -Directory).Count -ne $backupCount) { throw '重复 Gemini36 应用新增了备份。' }

    Write-Host 'STEP 4: switch Gemini36 to Stable'
    $stable = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Stable -AllowAdaptive
    if (-not $stable.Passed -or -not $stable.Changed -or $stable.PreviousMode -ne 'Gemini36') { throw 'Gemini36 到 Stable 回退结果错误。' }
    if ((Get-InstalledCompatibilityMode -InstallRoot $installRoot) -ne 'Stable') { throw '安装目录未回到 Stable。' }
    if ((Get-InstallHash $mainRelative) -ne $stableHashes.Main) { throw '回退后 main.js 未恢复稳定字节。' }
    if ((Get-InstallHash $workbenchRelative) -ne $stableHashes.Workbench) { throw '回退后 workbench 未恢复稳定字节。' }

    Write-Host 'STEP 5: restore exact backup'
    Restore-StableBackup -BackupDirectory $gemini.Backup | Out-Null
    if ((Get-InstallHash $mainRelative) -ne $stableHashes.Main) { throw 'Gemini36 精确备份未恢复 main.js。' }
    if ((Get-InstallHash $workbenchRelative) -ne $stableHashes.Workbench) { throw 'Gemini36 精确备份未恢复 workbench。' }

    Write-Host 'STEP 5A: switch Stable to combined Gemini37/Gemini36 with Agent Pro transaction'
    $combined = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Gemini37 -AgentProSourcePath $agentProSourcePath -AllowAdaptive
    if (-not $combined.Passed -or -not $combined.Changed -or $combined.PreviousMode -ne 'Stable') { throw '组合模式切换结果错误。' }
    $combinedMain = [IO.File]::ReadAllText((Join-Path $installRoot $mainRelative))
    $combinedWorkbench = [IO.File]::ReadAllText((Join-Path $installRoot $workbenchRelative))
    $patchedAgentPro = [IO.File]::ReadAllText($agentProSourcePath)
    if (-not $combinedMain.Contains('Gemini 3.8 Flash (High)') -or $combinedMain.Contains('Gemini 3.7 Flash') -or $combinedMain.Contains('Gemini 3.6 Flash')) { throw '组合模式目录未正确放行 3.8 High 或未剔除 3.7/3.6。' }
    if (-not $combinedWorkbench.Contains('_agGemini36Ids=new Set([1264,1265])') -or $combinedWorkbench.Contains('_agGemini37Ids')) { throw '组合模式 Workbench 未使用固定 3.6 桥。' }
    if (-not (Test-Gemini37AgentProSourceContent -Content $patchedAgentPro)) { throw 'Agent Pro 路由补丁未部署。' }
    if (-not (Test-Path -LiteralPath $agentProCompatPath -PathType Leaf)) { throw 'Agent Pro helper 未部署。' }
    $combinedStatus = Get-CompatibilityInstallStatus -InstallRoot $installRoot -Mode Gemini37 -AgentProSourcePath $agentProSourcePath
    if (-not $combinedStatus.Passed) { throw "组合模式静态复验失败：$($combinedStatus.Message)" }

    $combinedBackupCount = @(Get-ChildItem -LiteralPath $backupRoot -Directory).Count
    $secondCombined = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Gemini37 -AgentProSourcePath $agentProSourcePath -AllowAdaptive
    if ($secondCombined.Changed -or $null -ne $secondCombined.Backup) { throw '重复组合模式应用必须零修改、零备份。' }
    if (@(Get-ChildItem -LiteralPath $backupRoot -Directory).Count -ne $combinedBackupCount) { throw '重复组合模式应用新增了备份。' }

    $stableWithAgentPro = Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Stable -AgentProSourcePath $agentProSourcePath -AllowAdaptive
    if (-not $stableWithAgentPro.Passed -or -not $stableWithAgentPro.Changed) { throw '组合模式回退 Stable 失败。' }
    if ([IO.File]::ReadAllText($agentProSourcePath) -ne $agentProOriginal) { throw 'Stable 回退未精确恢复 Agent Pro source.js。' }
    if (Test-Path -LiteralPath $agentProCompatPath) { throw 'Stable 回退未删除 Gemini 3.7 helper。' }

    Restore-StableBackup -BackupDirectory $combined.Backup | Out-Null
    if ([IO.File]::ReadAllText($agentProSourcePath) -ne $agentProOriginal) { throw '组合模式备份未精确恢复 Agent Pro source.js。' }
    if (Test-Path -LiteralPath $agentProCompatPath) { throw '组合模式备份未恢复 helper 缺失态。' }

    $originalAppData = $env:APPDATA
    $failureAppData = Join-Path $temporaryRoot 'failure-appdata'
    $failureDatabase = Join-Path $failureAppData 'Antigravity\User\globalStorage\state.vscdb'
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($failureDatabase)) -Force | Out-Null
    [IO.File]::WriteAllText($failureDatabase, 'not a sqlite database', [Text.UTF8Encoding]::new($false))
    Write-Host 'STEP 6: inject cache failure and verify rollback'
    $failed = $false
    try {
        $env:APPDATA = $failureAppData
        try {
            Set-CompatibilityMode -InstallRoot $installRoot -BackupRoot $backupRoot -Mode Gemini36 -AllowAdaptive -ClearModelCache 2>$null | Out-Null
        } catch {
            $failed = $true
        }
    } finally {
        $env:APPDATA = $originalAppData
    }
    if (-not $failed) { throw '故障注入未触发 Gemini36 安装回滚。' }
    if ((Get-InstallHash $mainRelative) -ne $stableHashes.Main) { throw '失败回滚后 main.js 不一致。' }
    if ((Get-InstallHash $workbenchRelative) -ne $stableHashes.Workbench) { throw '失败回滚后 workbench 不一致。' }
    if ((Get-InstallHash $extensionRelative) -ne $stableHashes.Extension) { throw '失败回滚后 extension.js 不一致。' }
    if ((Get-InstallHash $bridgeRelative) -ne $stableHashes.Bridge) { throw '失败回滚后桥文件不一致。' }

    Write-Output 'PASS: multi-mode transaction, Agent Pro routing rollback, idempotency, and shared-patch preservation'
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}

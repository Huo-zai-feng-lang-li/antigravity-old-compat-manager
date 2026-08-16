$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot '..\scripts\StableMode.Core.psm1') -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT: $Message" }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) { throw "ASSERT: $Message; expected=[$Expected], actual=[$Actual]" }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    try { & $Action; throw "ASSERT: $Message" }
    catch {
        if ($_.Exception.Message -like 'ASSERT:*') { throw }
    }
}

$before = 'k.MetadataProvider.initialize(e),i.end(),f.UserStatusUpdater.getInstance().restartUpdateLoop(),i=l.JetskiTrace.task("extension activate: sentry init"),U.ElectronMainLsClient.initialize(e),W.LanguageServerClient.initialize(),await W.LanguageServerClient.getInstance().initAsync(),e.subscriptions.push(W.LanguageServerClient.getInstance()),i.end(),i=l.JetskiTrace.task("extension activate: unleash init")'
$expected = 'k.MetadataProvider.initialize(e),i.end(),i=l.JetskiTrace.task("extension activate: sentry init"),U.ElectronMainLsClient.initialize(e),W.LanguageServerClient.initialize(),await W.LanguageServerClient.getInstance().initAsync(),e.subscriptions.push(W.LanguageServerClient.getInstance()),f.UserStatusUpdater.getInstance().restartUpdateLoop(),i.end(),i=l.JetskiTrace.task("extension activate: unleash init")'

$after = ConvertTo-RestartSafeExtensionContent -Content $before
Assert-Equal $expected $after '用户状态更新器必须移到语言服务器完成初始化之后'
Assert-True (Test-RestartSafeExtensionContent -Content $after) '修复后结构检查应通过'
Assert-Equal $after (ConvertTo-RestartSafeExtensionContent -Content $after) '转换必须幂等'

$renamed = $before.Replace('k.MetadataProvider', 'meta.MetadataProvider').Replace('f.UserStatusUpdater', 'status.UserStatusUpdater').Replace('W.LanguageServerClient', 'ls.LanguageServerClient')
$renamedAfter = ConvertTo-RestartSafeExtensionContent -Content $renamed
Assert-True ($renamedAfter.Contains('ls.LanguageServerClient.getInstance()),status.UserStatusUpdater.getInstance().restartUpdateLoop(),i.end()')) '应适配压缩变量重命名'
Assert-True (Test-RestartSafeExtensionContent -Content $renamedAfter) '变量重命名后的结构检查应通过'

Assert-Throws { ConvertTo-RestartSafeExtensionContent -Content ($before.Replace('f.UserStatusUpdater.getInstance().restartUpdateLoop(),', '')) | Out-Null } '缺少旧锚点必须拒绝'
Assert-Throws { ConvertTo-RestartSafeExtensionContent -Content ($before + $before) | Out-Null } '重复激活锚点必须拒绝'
Assert-Throws { ConvertTo-RestartSafeExtensionContent -Content ($before.Replace('await W.LanguageServerClient.getInstance().initAsync(),', '')) | Out-Null } '缺少语言服务器初始化锚点必须拒绝'

Write-Output 'PASS: restart auth ordering, idempotency, renamed aliases, and fail-closed anchors'

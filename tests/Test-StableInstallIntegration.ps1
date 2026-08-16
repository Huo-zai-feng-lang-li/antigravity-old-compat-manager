$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot '..\scripts\StableMode.Core.psm1') -Force

$sourceRoot = 'D:\Antigravity'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntigravityStableTest-' + [guid]::NewGuid().ToString('N'))
$installRoot = Join-Path $temporaryRoot 'install'
$backupRoot = Join-Path $temporaryRoot 'backups'
$bridgeSource = Join-Path $PSScriptRoot '..\runtime\OneLSAgentProxyBridge.cjs'

try {
    $mainTarget = Join-Path $installRoot 'resources\app\out\main.js'
    $workbenchTarget = Join-Path $installRoot 'resources\app\out\vs\workbench\workbench.desktop.main.js'
    $productTarget = Join-Path $installRoot 'resources\app\product.json'
    $extensionTarget = Join-Path $installRoot 'resources\app\extensions\antigravity\dist\extension.js'
    $bridgeTarget = Join-Path $installRoot 'resources\app\dao-one-ls-agent-pro.cjs'
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($mainTarget)) -Force | Out-Null
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($workbenchTarget)) -Force | Out-Null
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($extensionTarget)) -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $installRoot 'Antigravity.exe') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'resources\app\out\main.js') -Destination $mainTarget
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'resources\app\out\vs\workbench\workbench.desktop.main.js') -Destination $workbenchTarget
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'resources\app\product.json') -Destination $productTarget
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'resources\app\extensions\antigravity\dist\extension.js') -Destination $extensionTarget

    $rawMainHash = (Get-FileHash -LiteralPath $mainTarget -Algorithm SHA256).Hash
    $rawWorkbenchHash = (Get-FileHash -LiteralPath $workbenchTarget -Algorithm SHA256).Hash
    $rawExtensionHash = (Get-FileHash -LiteralPath $extensionTarget -Algorithm SHA256).Hash
    $result = Set-StableMode -InstallRoot $installRoot -BackupRoot $backupRoot -AllowAdaptive
    if (-not $result.Passed) { throw '首次应用未通过。' }
    if ($result.SourceExtensionSha256 -ne $rawExtensionHash) { throw '未记录 extension.js 源哈希。' }
    if ((Get-FileHash -LiteralPath $extensionTarget -Algorithm SHA256).Hash -ne $result.TargetExtensionSha256) { throw 'extension.js 目标哈希与安装结果不一致。' }
    if (-not (Test-RestartSafeExtensionContent -Content ([IO.File]::ReadAllText($extensionTarget)))) { throw 'extension.js 修复后结构检查未通过。' }
    if (-not (Test-Path -LiteralPath $bridgeTarget -PathType Leaf)) { throw '未部署 OneLS Agent Pro 桥接文件。' }
    $expectedBridgeHash = (Get-FileHash -LiteralPath $bridgeSource -Algorithm SHA256).Hash
    if ($result.TargetBridgeSha256 -ne $expectedBridgeHash) { throw '安装结果未记录桥文件目标哈希。' }
    if ((Get-FileHash -LiteralPath $bridgeTarget -Algorithm SHA256).Hash -ne $expectedBridgeHash) { throw '桥文件未按原始字节部署。' }
    $firstManifest = Get-Content -LiteralPath (Join-Path $result.Backup 'manifest.json') -Raw | ConvertFrom-Json
    $firstBridgeEntry = @($firstManifest.entries | Where-Object { $_.source -eq $bridgeTarget })[0]
    if ($firstBridgeEntry.existed -or $null -ne $firstBridgeEntry.backup -or $null -ne $firstBridgeEntry.sha256) { throw '备份清单未正确表达桥文件原本不存在。' }
    $status = Get-StableInstallStatus $installRoot -ExpectedMainSha256 $result.TargetMainSha256 -ExpectedWorkbenchSha256 $result.TargetWorkbenchSha256 -ExpectedExtensionSha256 $result.TargetExtensionSha256 -ExpectedBridgeSha256 $result.TargetBridgeSha256 -Adapter $result.Adapter
    if (-not $status.Passed) { throw "首次应用后的静态检查未通过：$($status | ConvertTo-Json -Compress)" }

    $second = Set-StableMode -InstallRoot $installRoot -BackupRoot $backupRoot -AllowAdaptive
    if (-not $second.Passed) { throw '重复应用未通过。' }
    if ($second.Changed -or $null -ne $second.Backup) { throw "健康稳定模式重复应用必须零修改、零备份：$($second | ConvertTo-Json -Depth 8 -Compress)" }
    if ($second.TargetBridgeSha256 -ne $result.TargetBridgeSha256) { throw '重复安装桥文件必须幂等。' }
    $product = Get-Content -LiteralPath $productTarget -Raw | ConvertFrom-Json
    $product.ideVersion = '0.0.0-corrupt'
    [IO.File]::WriteAllText($productTarget, ($product | ConvertTo-Json -Depth 100), [Text.UTF8Encoding]::new($false))
    $repair = Set-StableMode -InstallRoot $installRoot -BackupRoot $backupRoot -AllowAdaptive
    if (-not $repair.Changed -or -not (Test-Path -LiteralPath $repair.Backup)) { throw '产品漂移修复必须修改并备份。' }
    $repairManifest = Get-Content -LiteralPath (Join-Path $repair.Backup 'manifest.json') -Raw | ConvertFrom-Json
    $repairBridgeEntry = @($repairManifest.entries | Where-Object { $_.source -eq $bridgeTarget })[0]
    if (-not $repairBridgeEntry.existed -or $repairBridgeEntry.sha256 -ne $expectedBridgeHash) { throw '修复备份未记录既有桥文件及其哈希。' }
    [IO.File]::WriteAllText($bridgeTarget, 'corrupt bridge', [Text.UTF8Encoding]::new($false))
    Restore-StableBackup -BackupDirectory $repair.Backup | Out-Null
    if ((Get-FileHash -LiteralPath $bridgeTarget -Algorithm SHA256).Hash -ne $expectedBridgeHash) { throw '原安装存在桥文件时，恢复必须按哈希还原。' }
    Restore-StableBackup -BackupDirectory $result.Backup | Out-Null
    if ((Get-FileHash -LiteralPath $mainTarget -Algorithm SHA256).Hash -ne $rawMainHash) { throw 'main.js 恢复后字节不一致。' }
    if ((Get-FileHash -LiteralPath $workbenchTarget -Algorithm SHA256).Hash -ne $rawWorkbenchHash) { throw 'workbench 恢复后字节不一致。' }
    if ((Get-FileHash -LiteralPath $extensionTarget -Algorithm SHA256).Hash -ne $rawExtensionHash) { throw 'extension.js 恢复后字节不一致。' }
    if (Test-Path -LiteralPath $bridgeTarget) { throw '原安装不存在桥文件时，恢复必须删除部署文件。' }

    $originalAppData = $env:APPDATA
    $failureAppData = Join-Path $temporaryRoot 'failure-appdata'
    $failureDatabase = Join-Path $failureAppData 'Antigravity\User\globalStorage\state.vscdb'
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($failureDatabase)) -Force | Out-Null
    [IO.File]::WriteAllText($failureDatabase, 'not a sqlite database', [Text.UTF8Encoding]::new($false))
    $installFailed = $false
    try {
        $env:APPDATA = $failureAppData
        try { Set-StableMode -InstallRoot $installRoot -BackupRoot $backupRoot -AllowAdaptive -ClearModelCache 2>$null | Out-Null }
        catch { $installFailed = $true }
    }
    finally {
        $env:APPDATA = $originalAppData
    }
    if (-not $installFailed) { throw '故障注入未触发安装失败。' }
    if ((Get-FileHash -LiteralPath $mainTarget -Algorithm SHA256).Hash -ne $rawMainHash) { throw '安装失败后 main.js 未回滚。' }
    if ((Get-FileHash -LiteralPath $workbenchTarget -Algorithm SHA256).Hash -ne $rawWorkbenchHash) { throw '安装失败后 workbench 未回滚。' }
    if ((Get-FileHash -LiteralPath $extensionTarget -Algorithm SHA256).Hash -ne $rawExtensionHash) { throw '安装失败后 extension.js 未回滚。' }
    if (Test-Path -LiteralPath $bridgeTarget) { throw '安装失败后新增桥文件未删除。' }

    Write-Output 'PASS: bridge deployment, manifest semantics, idempotency, byte-level restore, and failure rollback'
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}

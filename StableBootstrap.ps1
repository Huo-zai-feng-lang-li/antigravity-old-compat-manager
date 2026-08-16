[CmdletBinding()]
param(
    [string]$InstallRoot,
    [string]$StateRoot,
    [string]$AgentProSourcePath,
    [ValidateSet('Stable', 'Gemini37')]
    [string]$Mode,
    [switch]$CheckOnly,
    [switch]$NoLaunch,
    [switch]$InstallShortcut,
    [switch]$SkipModelCache,
    [switch]$StopRunningProcesses,
    [switch]$SuppressErrorDialog,
    [string]$ShortcutPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$standardError = [IO.StreamWriter]::new([Console]::OpenStandardError(), [Text.UTF8Encoding]::new($false))
$standardError.AutoFlush = $true
[Console]::SetError($standardError)

$projectRoot = $PSScriptRoot
$modulePath = Join-Path $projectRoot 'scripts\StableMode.Core.psm1'
if ([string]::IsNullOrWhiteSpace($StateRoot)) { $StateRoot = $projectRoot }
$settingsPath = Join-Path $StateRoot 'config\bootstrap-settings.json'
$profilesPath = Join-Path $StateRoot 'profiles\local-generated.json'
$backupRoot = Join-Path $StateRoot 'backups'
$logsRoot = Join-Path $StateRoot 'logs'
$currentPatchVersion = 'compatibility-v13-gemini37-real-route-gemini36'
$currentSchemaVersion = 8
Import-Module $modulePath -Force

function Get-BootstrapSettings {
    if (-not (Test-Path -LiteralPath $settingsPath)) { return [pscustomobject]@{} }
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    if ($null -eq $settings -or $settings -isnot [psobject]) { throw 'Bootstrap 配置格式无效。' }
    $settings
}

function Set-ObjectProperty {
    param($Target, [string]$Name, $Value)
    $property = $Target.PSObject.Properties[$Name]
    if ($null -eq $property) {
        $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    } else {
        $property.Value = $Value
    }
}

function Test-OptionalHashMatch {
    param([string]$Expected, [string]$Actual)
    if ([string]::IsNullOrWhiteSpace($Expected)) { return [string]::IsNullOrWhiteSpace($Actual) }
    $Expected -eq $Actual
}

function Resolve-BootstrapMode {
    param([string]$RequestedMode, $Settings, [bool]$Explicit)
    if ($Explicit) { return $RequestedMode }
    $saved = $Settings.PSObject.Properties['selectedMode']?.Value
    if ([string]::IsNullOrWhiteSpace($saved)) { return 'Stable' }
    if ($saved -eq 'Gemini36') { return 'Gemini37' }
    if ($saved -notin @('Stable', 'Gemini37')) { throw "Bootstrap 配置包含非法模式：$saved" }
    [string]$saved
}

function Save-BootstrapSettings {
    param($Settings, [string]$Root, [string]$SelectedMode)
    Set-ObjectProperty $Settings 'installRoot' $Root
    Set-ObjectProperty $Settings 'selectedMode' $SelectedMode
    Set-ObjectProperty $Settings 'lastSuccessfulMode' $SelectedMode
    Write-JsonAtomic -Path $settingsPath -Value $Settings
}

function Get-BootstrapProfiles {
    if (-not (Test-Path -LiteralPath $profilesPath)) { return @() }
    $value = Get-Content -LiteralPath $profilesPath -Raw | ConvertFrom-Json
    @($value)
}

function Write-JsonAtomic {
    param([string]$Path, $Value)
    $directory = Split-Path $Path -Parent
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporary = "$Path.tmp"
    [IO.File]::WriteAllText($temporary, ($Value | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Resolve-BootstrapRoot {
    param([string]$RequestedRoot, $Settings)
    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) { return [IO.Path]::GetFullPath($RequestedRoot).TrimEnd('\', '/') }
    $savedRoot = $Settings.PSObject.Properties['installRoot']?.Value
    if (-not [string]::IsNullOrWhiteSpace($savedRoot)) {
        if (Test-Path -LiteralPath (Join-Path $savedRoot 'Antigravity.exe')) { return $savedRoot }
    }
    Find-AntigravityInstallRoots |
        Sort-Object { (Get-Item -LiteralPath (Join-Path $_ 'resources\app\out\main.js')).LastWriteTimeUtc } -Descending |
        Select-Object -First 1
}

function Get-HashPair {
    param([string]$Root, [string]$AgentProSource)
    $bridgePath = Join-Path $Root 'resources\app\dao-one-ls-agent-pro.cjs'
    $agentProCompatPath = if ([string]::IsNullOrWhiteSpace($AgentProSource)) {
        $null
    } else {
        Join-Path ([IO.Path]::GetDirectoryName($AgentProSource)) '_ag-gemini37-compat.cjs'
    }
    [pscustomobject]@{
        Main = (Get-FileHash -LiteralPath (Join-Path $Root 'resources\app\out\main.js') -Algorithm SHA256).Hash
        Workbench = (Get-FileHash -LiteralPath (Join-Path $Root 'resources\app\out\vs\workbench\workbench.desktop.main.js') -Algorithm SHA256).Hash
        Extension = (Get-FileHash -LiteralPath (Join-Path $Root 'resources\app\extensions\antigravity\dist\extension.js') -Algorithm SHA256).Hash
        Bridge = if (Test-Path -LiteralPath $bridgePath -PathType Leaf) { (Get-FileHash -LiteralPath $bridgePath -Algorithm SHA256).Hash } else { $null }
        AgentProSource = if ([string]::IsNullOrWhiteSpace($AgentProSource)) { $null } else { (Get-FileHash -LiteralPath $AgentProSource -Algorithm SHA256).Hash }
        AgentProCompat = if ($null -ne $agentProCompatPath -and (Test-Path -LiteralPath $agentProCompatPath -PathType Leaf)) { (Get-FileHash -LiteralPath $agentProCompatPath -Algorithm SHA256).Hash } else { $null }
    }
}

function Test-BootstrapProductState {
    param([string]$Root, $Pair)
    try {
        $product = Get-Content -LiteralPath (Join-Path $Root 'resources\app\product.json') -Raw | ConvertFrom-Json
        $date = if ($product.date -is [datetime]) {
            $product.date.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        } else { [string]$product.date }
        $checksum = [Convert]::ToBase64String([Convert]::FromHexString($Pair.Workbench)).TrimEnd('=')
        $actualChecksum = $product.checksums.PSObject.Properties['vs/workbench/workbench.desktop.main.js']?.Value
        $product.ideVersion -eq '2.5.5' -and
            $date -eq '2026-08-13T08:28:19.366Z' -and
            $actualChecksum -eq $checksum
    } catch { $false }
}

function Find-TargetProfile {
    param($Pair, $Profiles, [string]$Mode)
    if ($null -eq $Profiles) { return $null }
    foreach ($profile in @($Profiles)) {
        $profileMode = $profile.PSObject.Properties['mode']?.Value
        if ([string]::IsNullOrWhiteSpace($profileMode)) { $profileMode = 'Stable' }
        if ($profileMode -ne $Mode) { continue }
        $main = $profile.PSObject.Properties['targetMainSha256']?.Value
        $workbench = $profile.PSObject.Properties['targetWorkbenchSha256']?.Value
        $extension = $profile.PSObject.Properties['targetExtensionSha256']?.Value
        $bridge = $profile.PSObject.Properties['targetBridgeSha256']?.Value
        $agentProSource = $profile.PSObject.Properties['targetAgentProSha256']?.Value
        $agentProCompat = $profile.PSObject.Properties['targetAgentProCompatSha256']?.Value
        $adapter = $profile.PSObject.Properties['adapter']?.Value
        $obsolete = $adapter -in @('stable-anchors-v1', 'catalog-filter-https-v1', 'catalog-filter-http-v2')
        $schemaVersion = $profile.PSObject.Properties['schemaVersion']?.Value
        $patchVersion = $profile.PSObject.Properties['patchVersion']?.Value
        if ($schemaVersion -ne $currentSchemaVersion -or $patchVersion -ne $currentPatchVersion) { continue }
        if ($main -eq $Pair.Main -and $workbench -eq $Pair.Workbench -and $extension -eq $Pair.Extension -and
            -not [string]::IsNullOrWhiteSpace($bridge) -and $bridge -eq $Pair.Bridge -and
            (Test-OptionalHashMatch $agentProSource $Pair.AgentProSource) -and
            (Test-OptionalHashMatch $agentProCompat $Pair.AgentProCompat) -and -not $obsolete) { return $profile }
    }
    $null
}

function Get-UniqueTargetProfiles {
    param($Profiles, $Pair, [string]$Mode)

    $result = [Collections.Generic.List[object]]::new()
    $targetSeen = $false
    foreach ($profile in @($Profiles)) {
        $profileMode = $profile.PSObject.Properties['mode']?.Value
        if ([string]::IsNullOrWhiteSpace($profileMode)) { $profileMode = 'Stable' }
        $sameTarget = $profileMode -eq $Mode -and
            $profile.PSObject.Properties['schemaVersion']?.Value -eq $currentSchemaVersion -and
            $profile.PSObject.Properties['patchVersion']?.Value -eq $currentPatchVersion -and
            $profile.PSObject.Properties['targetMainSha256']?.Value -eq $Pair.Main -and
            $profile.PSObject.Properties['targetWorkbenchSha256']?.Value -eq $Pair.Workbench -and
            $profile.PSObject.Properties['targetExtensionSha256']?.Value -eq $Pair.Extension -and
            $profile.PSObject.Properties['targetBridgeSha256']?.Value -eq $Pair.Bridge -and
            (Test-OptionalHashMatch $profile.PSObject.Properties['targetAgentProSha256']?.Value $Pair.AgentProSource) -and
            (Test-OptionalHashMatch $profile.PSObject.Properties['targetAgentProCompatSha256']?.Value $Pair.AgentProCompat)
        if ($sameTarget -and $targetSeen) { continue }
        if ($sameTarget) { $targetSeen = $true }
        $result.Add($profile)
    }
    ,$result.ToArray()
}

function Register-BootstrapProfile {
    param($Result, [string]$Mode)
    $profiles = [Collections.Generic.List[object]]::new()
    foreach ($profile in Get-BootstrapProfiles) { $profiles.Add($profile) }
    $sourceExists = $false
    foreach ($profile in $profiles) {
        $profileMode = $profile.PSObject.Properties['mode']?.Value
        if ([string]::IsNullOrWhiteSpace($profileMode)) { $profileMode = 'Stable' }
        if ($profileMode -ne $Mode) { continue }
        $sourceAgentPro = $profile.PSObject.Properties['sourceAgentProSha256']?.Value
        $sourceAgentProCompat = $profile.PSObject.Properties['sourceAgentProCompatSha256']?.Value
        $targetAgentPro = $profile.PSObject.Properties['targetAgentProSha256']?.Value
        $targetAgentProCompat = $profile.PSObject.Properties['targetAgentProCompatSha256']?.Value
        $matchesSource = $profile.PSObject.Properties['sourceMainSha256']?.Value -eq $Result.SourceMainSha256 -and
            $profile.PSObject.Properties['sourceWorkbenchSha256']?.Value -eq $Result.SourceWorkbenchSha256 -and
            ([string]::IsNullOrWhiteSpace($sourceAgentPro) -or (Test-OptionalHashMatch $sourceAgentPro $Result.SourceAgentProSha256)) -and
            ([string]::IsNullOrWhiteSpace($sourceAgentProCompat) -or (Test-OptionalHashMatch $sourceAgentProCompat $Result.SourceAgentProCompatSha256))
        $targetsSource = $profile.PSObject.Properties['targetMainSha256']?.Value -eq $Result.SourceMainSha256 -and
            $profile.PSObject.Properties['targetWorkbenchSha256']?.Value -eq $Result.SourceWorkbenchSha256 -and
            ([string]::IsNullOrWhiteSpace($targetAgentPro) -or (Test-OptionalHashMatch $targetAgentPro $Result.SourceAgentProSha256)) -and
            ([string]::IsNullOrWhiteSpace($targetAgentProCompat) -or (Test-OptionalHashMatch $targetAgentProCompat $Result.SourceAgentProCompatSha256))
        if (-not ($matchesSource -or $targetsSource)) { continue }
        Set-ObjectProperty $profile 'schemaVersion' $currentSchemaVersion
        Set-ObjectProperty $profile 'mode' $Mode
        Set-ObjectProperty $profile 'patchVersion' $currentPatchVersion
        Set-ObjectProperty $profile 'targetMainSha256' $Result.TargetMainSha256
        Set-ObjectProperty $profile 'targetWorkbenchSha256' $Result.TargetWorkbenchSha256
        Set-ObjectProperty $profile 'targetExtensionSha256' $Result.TargetExtensionSha256
        Set-ObjectProperty $profile 'targetBridgeSha256' $Result.TargetBridgeSha256
        Set-ObjectProperty $profile 'targetAgentProSha256' $Result.TargetAgentProSha256
        Set-ObjectProperty $profile 'targetAgentProCompatSha256' $Result.TargetAgentProCompatSha256
        Set-ObjectProperty $profile 'adapter' $Result.Adapter
        if ($matchesSource) {
            Set-ObjectProperty $profile 'sourceAgentProSha256' $Result.SourceAgentProSha256
            Set-ObjectProperty $profile 'sourceAgentProCompatSha256' $Result.SourceAgentProCompatSha256
            $sourceExists = $true
        }
    }
    if (-not $sourceExists) {
        $profiles.Add([pscustomobject]@{
            schemaVersion = $currentSchemaVersion
            mode = $Mode
            patchVersion = $currentPatchVersion
            createdUtc = [DateTime]::UtcNow.ToString('O')
            sourceMainSha256 = $Result.SourceMainSha256
            sourceWorkbenchSha256 = $Result.SourceWorkbenchSha256
            sourceExtensionSha256 = $Result.SourceExtensionSha256
            sourceBridgeSha256 = $Result.SourceBridgeSha256
            sourceAgentProSha256 = $Result.SourceAgentProSha256
            sourceAgentProCompatSha256 = $Result.SourceAgentProCompatSha256
            targetMainSha256 = $Result.TargetMainSha256
            targetWorkbenchSha256 = $Result.TargetWorkbenchSha256
            targetExtensionSha256 = $Result.TargetExtensionSha256
            targetBridgeSha256 = $Result.TargetBridgeSha256
            targetAgentProSha256 = $Result.TargetAgentProSha256
            targetAgentProCompatSha256 = $Result.TargetAgentProCompatSha256
            adapter = $Result.Adapter
        })
    }
    $targetPair = [pscustomobject]@{
        Main = $Result.TargetMainSha256
        Workbench = $Result.TargetWorkbenchSha256
        Extension = $Result.TargetExtensionSha256
        Bridge = $Result.TargetBridgeSha256
        AgentProSource = $Result.TargetAgentProSha256
        AgentProCompat = $Result.TargetAgentProCompatSha256
    }
    $profiles = @(Get-UniqueTargetProfiles -Profiles $profiles -Pair $targetPair -Mode $Mode)
    Write-JsonAtomic -Path $profilesPath -Value $profiles
}

function New-StableShortcut {
    param([string]$Root, [string]$RequestedPath)
    $shortcutPath = if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
        Join-Path ([Environment]::GetFolderPath('Desktop')) 'Antigravity 稳定版.lnk'
    } else {
        [IO.Path]::GetFullPath($RequestedPath)
    }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\wscript.exe'
    $shortcut.Arguments = "`"$(Join-Path $projectRoot 'Launch-StableHidden.vbs')`""
    $shortcut.WorkingDirectory = $projectRoot
    $shortcut.IconLocation = "$(Join-Path $Root 'Antigravity.exe'),0"
    $shortcut.Save()
    $shortcutPath
}

function Write-BootstrapDiagnostic {
    param([string]$Root, [string]$AgentProSource, $Pair, [string]$Mode, [string]$Message)
    New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
    $path = Join-Path $logsRoot ("bootstrap-blocked-$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')).json")
    Write-JsonAtomic -Path $path -Value ([pscustomobject]@{
        createdUtc = [DateTime]::UtcNow.ToString('O')
        installRoot = $Root
        mainSha256 = $Pair.Main
        workbenchSha256 = $Pair.Workbench
        extensionSha256 = $Pair.Extension
        bridgeSha256 = $Pair.Bridge
        agentProSourcePath = $AgentProSource
        agentProSourceSha256 = $Pair.AgentProSource
        agentProCompatSha256 = $Pair.AgentProCompat
        mode = $Mode
        message = $Message
    })
    $path
}

$bootstrapSettings = Get-BootstrapSettings
$selectedMode = Resolve-BootstrapMode -RequestedMode $Mode -Settings $bootstrapSettings -Explicit:$PSBoundParameters.ContainsKey('Mode')
$resolvedRoot = Resolve-BootstrapRoot $InstallRoot $bootstrapSettings
if ([string]::IsNullOrWhiteSpace($resolvedRoot)) { throw '未检测到 Antigravity 安装目录。' }
$resolvedAgentProSource = Find-AgentProSourcePath -ExplicitPath $AgentProSourcePath
if ($selectedMode -eq 'Gemini37' -and [string]::IsNullOrWhiteSpace($resolvedAgentProSource)) {
    throw '未检测到 Agent Pro source.js，无法部署 Gemini 3.7 真实路由补丁。'
}
$pair = Get-HashPair $resolvedRoot $resolvedAgentProSource
$profiles = Get-BootstrapProfiles
$targetProfile = Find-TargetProfile $pair $profiles $selectedMode
if ($selectedMode -eq 'Gemini37') {
    $workbenchPath = Join-Path $resolvedRoot 'resources\app\out\vs\workbench\workbench.desktop.main.js'
    $workbenchText = [IO.File]::ReadAllText($workbenchPath)
    if ($workbenchText.Contains('_agGemini37')) { $targetProfile = $null }
}
$shortcutResult = if ($InstallShortcut) { New-StableShortcut $resolvedRoot $ShortcutPath } else { $null }
$launchArguments = @('--remote-debugging-port=9000')

if ($CheckOnly) {
    [pscustomobject]@{
        Root = $resolvedRoot
        MainSha256 = $pair.Main
        WorkbenchSha256 = $pair.Workbench
        ExtensionSha256 = $pair.Extension
        BridgeSha256 = $pair.Bridge
        AgentProSourcePath = $resolvedAgentProSource
        AgentProSourceSha256 = $pair.AgentProSource
        AgentProCompatSha256 = $pair.AgentProCompat
        SelectedMode = $selectedMode
        KnownTarget = $null -ne $targetProfile
        KnownStableTarget = $selectedMode -eq 'Stable' -and $null -ne $targetProfile
        ShortcutPath = $shortcutResult
    } | ConvertTo-Json -Depth 10
    exit 0
}

try {
    $needsRepair = $null -eq $targetProfile
    if ($null -ne $targetProfile) {
        $needsRepair = -not (Test-BootstrapProductState -Root $resolvedRoot -Pair $pair)
    }
    if ($needsRepair) {
        $result = Set-CompatibilityMode `
            -InstallRoot $resolvedRoot `
            -BackupRoot $backupRoot `
            -Mode $selectedMode `
            -AgentProSourcePath $resolvedAgentProSource `
            -ClearModelCache:(-not $SkipModelCache) `
            -AllowAdaptive `
            -StopRunningProcesses:$StopRunningProcesses
        Register-BootstrapProfile $result $selectedMode
    } else {
        $uniqueProfiles = @(Get-UniqueTargetProfiles -Profiles $profiles -Pair $pair -Mode $selectedMode)
        if ($uniqueProfiles.Count -ne @($profiles).Count) {
            Write-JsonAtomic -Path $profilesPath -Value $uniqueProfiles
        }
    }
    Save-BootstrapSettings -Settings $bootstrapSettings -Root $resolvedRoot -SelectedMode $selectedMode
    if ($InstallShortcut -and $null -eq $shortcutResult) { New-StableShortcut $resolvedRoot $ShortcutPath | Out-Null }
    if (-not $NoLaunch) {
        Start-Process -FilePath (Join-Path $resolvedRoot 'Antigravity.exe') -ArgumentList $launchArguments
    }
    exit 0
}
catch {
    $diagnostic = Write-BootstrapDiagnostic -Root $resolvedRoot -AgentProSource $resolvedAgentProSource -Pair $pair -Mode $selectedMode -Message $_.Exception.Message
    $message = "$($_.Exception.Message)`r`n`r`n诊断：$diagnostic"
    if ($SuppressErrorDialog) {
        [Console]::Error.WriteLine($message)
    } else {
        Add-Type -AssemblyName System.Windows.Forms
        [Windows.Forms.MessageBox]::Show($message, '稳定启动失败', 'OK', 'Error') | Out-Null
    }
    exit 1
}

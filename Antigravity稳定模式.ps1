[CmdletBinding()]
param(
    [ValidateSet('Gui', 'Diagnose', 'Apply', 'Restore')]
    [string]$Mode = 'Gui',
    [ValidateSet('Stable', 'Gemini37')]
    [string]$CompatibilityMode = 'Stable',
    [string]$InstallRoot,
    [string]$BackupDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = $PSScriptRoot
$modulePath = Join-Path $projectRoot 'scripts\StableMode.Core.psm1'
$bootstrapPath = Join-Path $projectRoot 'StableBootstrap.ps1'
$catalogProbePath = Join-Path $projectRoot 'tools\CdpModelCatalog.mjs'
$officialCatalogPath = Join-Path $projectRoot 'tools\OfficialModelCatalog.mjs'
$backupRoot = Join-Path $projectRoot 'backups'
Import-Module $modulePath -Force

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Find-AntigravityInstallRoots | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($InstallRoot)) { $InstallRoot = 'D:\Antigravity' }

function Format-Status {
    param($Status)
    @(
        "结果：$($Status.Message)"
        "目标模式：$($Status.Mode)"
        "当前模式：$($Status.InstalledMode)"
        "目录：$($Status.Root)"
        "main.js：$($Status.MainSha256)"
        "workbench：$($Status.WorkbenchSha256)"
        "伪装版本：$($Status.IdeVersion)"
    ) -join [Environment]::NewLine
}

function Get-SelectedCompatibilityMode {
    param($StableRadio, $Gemini37Radio)
    if ($Gemini37Radio.Checked) { return 'Gemini37' }
    if ($StableRadio.Checked) { return 'Stable' }
    throw '请选择兼容模式。'
}

function Invoke-CapturedProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [hashtable]$EnvironmentVariables = @{},
        [int]$TimeoutMs = 0
    )

    $pinfo = [System.Diagnostics.ProcessStartInfo]::new($FilePath)
    foreach ($argument in $ArgumentList) { [void]$pinfo.ArgumentList.Add($argument) }
    foreach ($name in $EnvironmentVariables.Keys) { $pinfo.Environment[$name] = [string]$EnvironmentVariables[$name] }
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $pinfo.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)

    $proc = [System.Diagnostics.Process]::Start($pinfo)
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $applicationType = 'System.Windows.Forms.Application' -as [type]
    try {
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        while (-not $proc.HasExited) {
            if ($null -ne $applicationType) { $applicationType::DoEvents() }
            if ($TimeoutMs -gt 0 -and $stopwatch.ElapsedMilliseconds -ge $TimeoutMs) {
                $proc.Kill($true)
                $proc.WaitForExit()
                throw "外部命令执行超时：$FilePath"
            }
            Start-Sleep -Milliseconds 50
        }
        [pscustomobject]@{
            ExitCode = $proc.ExitCode
            StandardOutput = $stdoutTask.GetAwaiter().GetResult()
            StandardError = $stderrTask.GetAwaiter().GetResult()
        }
    }
    finally {
        $stopwatch.Stop()
        $proc.Dispose()
    }
}

function Invoke-BootstrapMode {
    param([string]$Root, [string]$SelectedMode, [switch]$NoLaunch, [switch]$StopRunningProcesses)
    $arguments = @(
        '-NoProfile', '-File', $bootstrapPath,
        '-InstallRoot', $Root,
        '-StateRoot', $projectRoot,
        '-Mode', $SelectedMode
    )
    if ($NoLaunch) { $arguments += '-NoLaunch' }
    if ($StopRunningProcesses) { $arguments += '-StopRunningProcesses' }
    $arguments += '-SuppressErrorDialog'

    $result = Invoke-CapturedProcess -FilePath 'pwsh' -ArgumentList $arguments
    if ($result.ExitCode -ne 0) {
        $errDetail = if ($result.StandardError.Trim()) { $result.StandardError.Trim() } else { $result.StandardOutput.Trim() }
        throw "$SelectedMode 模式应用失败，退出码：$($result.ExitCode)`n$errDetail"
    }
    Get-CompatibilityInstallStatus -InstallRoot $Root -Mode $SelectedMode
}

function Invoke-ApplySelectedMode {
    param([string]$Root, [string]$SelectedMode)
    Invoke-BootstrapMode -Root $Root -SelectedMode $SelectedMode -StopRunningProcesses
}

function Test-TcpPort {
    param([string]$HostName, [int]$Port, [int]$TimeoutMs = 250)
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $connected = $client.ConnectAsync($HostName, $Port)
        $connected.Wait($TimeoutMs) -and $client.Connected
    }
    catch { $false }
    finally { $client.Dispose() }
}

function Get-OfficialModelCatalog {
    if (-not (Test-Path -LiteralPath $officialCatalogPath -PathType Leaf)) { throw '缺少官方模型目录查询器。' }
    $environment = @{}
    if (Test-TcpPort -HostName '127.0.0.1' -Port 51081) {
        $environment.HTTP_PROXY = 'http://127.0.0.1:51081'
        $environment.HTTPS_PROXY = 'http://127.0.0.1:51081'
        $environment.NO_PROXY = '127.0.0.1,localhost'
    }
    $result = Invoke-CapturedProcess `
        -FilePath 'node' `
        -ArgumentList @('--use-env-proxy', $officialCatalogPath) `
        -EnvironmentVariables $environment `
        -TimeoutMs 15000
    if ($result.ExitCode -ne 0) { throw $result.StandardError.Trim() }
    $result.StandardOutput | ConvertFrom-Json
}

function Get-ModelCatalogReport {
    $official = Get-OfficialModelCatalog
    $report = @(
        "官方公开推理模型（实时读取，共 $(@($official.models).Count) 个）"
        $official.models | ForEach-Object { "- $_" }
        "来源：$($official.source)"
        "查询时间：$(([datetime]$official.fetchedAt).ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss'))"
        ''
        '说明：Gemini 3.7 已通过兼容名单放行；其他未知新模型仍不会自动进入 IDE 下拉框。'
        ''
        '旧版 IDE 当前可见模型'
    )

    if (-not (Test-TcpPort -HostName '127.0.0.1' -Port 9000)) {
        return ($report + '未启用调试端口，仅展示官方公开目录。') -join [Environment]::NewLine
    }
    if (-not (Test-Path -LiteralPath $catalogProbePath -PathType Leaf)) {
        return ($report + '缺少旧版 IDE 目录检测器。') -join [Environment]::NewLine
    }

    try {
        $currentResult = Invoke-CapturedProcess `
            -FilePath 'node' `
            -ArgumentList @($catalogProbePath, 'http://127.0.0.1:9000/json/list') `
            -TimeoutMs 10000
        $current = $currentResult.StandardOutput | ConvertFrom-Json
        $report += if (@($current.present).Count -gt 0) { $current.present | ForEach-Object { "- $_" } } else { '当前下拉框未返回模型。' }
        if (@($current.low).Count -gt 0) { $report += "警告：检测到应屏蔽的 Low 模型：$($current.low -join '、')" }
    }
    catch {
        $report += "检测失败：$($_.Exception.Message)"
    }
    $report -join [Environment]::NewLine
}

function Show-StableModeGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [Windows.Forms.Application]::EnableVisualStyles()

    $form = [Windows.Forms.Form]@{
        Text = 'Antigravity 旧版兼容管理器'
        Width = 780
        Height = 560
        StartPosition = 'CenterScreen'
        Font = [Drawing.Font]::new('Microsoft YaHei UI', 10)
    }
    $pathBox = [Windows.Forms.TextBox]@{ Left = 18; Top = 22; Width = 620; Text = $InstallRoot }
    $browse = [Windows.Forms.Button]@{ Left = 650; Top = 19; Width = 95; Text = '选择目录' }
    $stableRadio = [Windows.Forms.RadioButton]@{
        Left = 18; Top = 62; Width = 210; Text = '稳定模式（仅 Claude）'
        Checked = $CompatibilityMode -eq 'Stable'
    }
    $gemini37Radio = [Windows.Forms.RadioButton]@{
        Left = 245; Top = 62; AutoSize = $true; Text = 'Gemini 3.7 兼容模式（保留 Claude）'
        Checked = $CompatibilityMode -eq 'Gemini37'
    }
    $diagnose = [Windows.Forms.Button]@{ Left = 18; Top = 98; Width = 120; Height = 36; Text = '检测状态' }
    $apply = [Windows.Forms.Button]@{ Left = 150; Top = 98; Width = 170; Height = 36; Text = '应用并启动' }
    $restore = [Windows.Forms.Button]@{ Left = 332; Top = 98; Width = 150; Height = 36; Text = '恢复最近备份' }
    $catalog = [Windows.Forms.Button]@{ Left = 500; Top = 98; Width = 150; Height = 36; Text = '检测模型目录' }
    $output = [Windows.Forms.TextBox]@{
        Left = 18; Top = 150; Width = 727; Height = 350; Multiline = $true
        ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = [Drawing.Color]::White
    }
    $form.Controls.AddRange(@($pathBox, $browse, $stableRadio, $gemini37Radio, $diagnose, $apply, $restore, $catalog, $output))

    $actionButtons = @($diagnose, $apply, $restore, $catalog, $browse)
    $setUiState = {
        param([bool]$enabled, [string]$busyMessage = '')
        foreach ($btn in $actionButtons) { $btn.Enabled = $enabled }
        if (-not $enabled -and $busyMessage) {
            $output.Text = $busyMessage
        }
        [System.Windows.Forms.Application]::DoEvents()
    }

    $browse.Add_Click({
        $picker = [Windows.Forms.FolderBrowserDialog]::new()
        $picker.SelectedPath = $pathBox.Text
        if ($picker.ShowDialog() -eq 'OK') { $pathBox.Text = $picker.SelectedPath }
    })
    $diagnose.Add_Click({
        try {
            & $setUiState $false '正在检测组件与环境状态，请稍候...'
            $selected = Get-SelectedCompatibilityMode $stableRadio $gemini37Radio
            $output.Text = Format-Status (Get-CompatibilityInstallStatus -InstallRoot $pathBox.Text -Mode $selected)
        } catch { $output.Text = "检测失败：$($_.Exception.Message)" }
        finally { & $setUiState $true }
    })
    $apply.Add_Click({
        try {
            $selected = Get-SelectedCompatibilityMode $stableRadio $gemini37Radio
            $answer = [Windows.Forms.MessageBox]::Show("将关闭 $pathBox.Text 下的 Antigravity/语言服务器，清理模型缓存，应用 $selected 并启动 IDE，是否继续？", '确认', 'YesNo', 'Warning')
            if ($answer -ne 'Yes') { return }
            & $setUiState $false "正在应用 $selected 模式并拉起 IDE，请稍候...`r`n(在此期间界面保持响应，请勿关闭窗口)"
            $status = Invoke-ApplySelectedMode -Root $pathBox.Text -SelectedMode $selected
            $output.Text = Format-Status $status
        } catch { $output.Text = "失败：$($_.Exception.Message)" }
        finally { & $setUiState $true }
    })
    $restore.Add_Click({
        try {
            & $setUiState $false '正在恢复备份，请稍候...'
            $latest = Get-LatestStableBackup $backupRoot
            if (-not $latest) { throw '没有可恢复的备份。' }
            $output.Text = Restore-StableBackup $latest
        } catch { $output.Text = "恢复失败：$($_.Exception.Message)" }
        finally { & $setUiState $true }
    })
    $catalog.Add_Click({
        try {
            & $setUiState $false '正在检测模型目录 API，请稍候...'
            $output.Text = Get-ModelCatalogReport
        } catch { $output.Text = "模型目录检测失败：$($_.Exception.Message)" }
        finally { & $setUiState $true }
    })

    $output.Text = Format-Status (Get-CompatibilityInstallStatus -InstallRoot $pathBox.Text -Mode $CompatibilityMode)
    $refreshTarget = {
        try {
            $selected = Get-SelectedCompatibilityMode $stableRadio $gemini37Radio
            $output.Text = Format-Status (Get-CompatibilityInstallStatus -InstallRoot $pathBox.Text -Mode $selected)
        } catch { $output.Text = "检测失败：$($_.Exception.Message)" }
    }
    $stableRadio.Add_CheckedChanged($refreshTarget)
    $gemini37Radio.Add_CheckedChanged($refreshTarget)
    [void]$form.ShowDialog()
}

switch ($Mode) {
    'Diagnose' { Format-Status (Get-CompatibilityInstallStatus -InstallRoot $InstallRoot -Mode $CompatibilityMode) }
    'Apply' { Invoke-BootstrapMode -Root $InstallRoot -SelectedMode $CompatibilityMode -NoLaunch | Format-List }
    'Restore' {
        if (-not $BackupDirectory) { $BackupDirectory = Get-LatestStableBackup $backupRoot }
        if (-not $BackupDirectory) { throw '没有可恢复的备份。' }
        Restore-StableBackup $BackupDirectory
    }
    default { Show-StableModeGui }
}

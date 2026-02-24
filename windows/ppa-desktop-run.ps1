param(
  # Optional workspace file argument when started via .ppaw/.ppa association.
  [string]$WorkspaceFile
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Tell Windows this is its own application so the taskbar shows our icon
# instead of the generic powershell.exe icon.
try {
  Add-Type -MemberDefinition @'
[DllImport("shell32.dll", SetLastError = true)]
public static extern void SetCurrentProcessExplicitAppUserModelID(
    [MarshalAs(UnmanagedType.LPWStr)] string AppID);
'@ -Namespace "PPA" -Name "AppId"
  [PPA.AppId]::SetCurrentProcessExplicitAppUserModelID("KNCV.PPA.Desktop")
} catch { }

# Resolve key paths early so we can set the window title/icon correctly
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ComposeDir  = Join-Path $ProjectRoot "local-dev"

# --- UI helpers --------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Starting PPA Desktop"
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ClientSize = New-Object System.Drawing.Size(600, 380)

$iconPath = Join-Path $ScriptDir "ppa-logo.ico"
if (Test-Path $iconPath) {
  try {
    $form.Icon = New-Object System.Drawing.Icon($iconPath)
  } catch {
    # Non-fatal if the icon cannot be loaded
  }
}

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(12, 12)
$titleLabel.Font = New-Object System.Drawing.Font(
  [System.Drawing.SystemFonts]::DefaultFont.FontFamily,
  11,
  [System.Drawing.FontStyle]::Bold
)
$titleLabel.Text = "PPA Desktop is starting..."
$form.Controls.Add($titleLabel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(12, 40)
$statusLabel.Text = "Preparing startup..."
$form.Controls.Add($statusLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(12, 65)
$progressBar.Size = New-Object System.Drawing.Size(560, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$form.Controls.Add($progressBar)

$subStatusLabel = New-Object System.Windows.Forms.Label
$subStatusLabel.AutoSize = $true
$subStatusLabel.Location = New-Object System.Drawing.Point(12, 90)
$subStatusLabel.Text = ""
$subStatusLabel.Visible = $false
$form.Controls.Add($subStatusLabel)

$subProgressBar = New-Object System.Windows.Forms.ProgressBar
$subProgressBar.Location = New-Object System.Drawing.Point(12, 108)
$subProgressBar.Size = New-Object System.Drawing.Size(560, 16)
$subProgressBar.Minimum = 0
$subProgressBar.Maximum = 100
$subProgressBar.Visible = $false
$form.Controls.Add($subProgressBar)

$logTextBox = New-Object System.Windows.Forms.TextBox
$logTextBox.Location = New-Object System.Drawing.Point(12, 130)
$logTextBox.Size = New-Object System.Drawing.Size(560, 205)
$logTextBox.Multiline = $true
$logTextBox.ScrollBars = 'Vertical'
$logTextBox.ReadOnly = $true
$logTextBox.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($logTextBox)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Enabled = $false
$closeButton.Size = New-Object System.Drawing.Size(90, 28)
$closeButton.Location = New-Object System.Drawing.Point(482, 340)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

$script:UiStatusLabel    = $statusLabel
$script:UiProgressBar    = $progressBar
$script:UiSubStatusLabel = $subStatusLabel
$script:UiSubProgressBar = $subProgressBar
$script:UiLogTextBox     = $logTextBox
$script:UiForm           = $form
$script:UiCloseButton    = $closeButton
$script:ExitAfterUpdate  = $false

function Write-UiLog {
  param(
    [string]$Message,
    [switch]$IsError
  )

  $timestamp = (Get-Date).ToString("HH:mm:ss")
  $line = "[$timestamp] $Message"

  $wroteToUi = $false

  try {
    if ($script:UiLogTextBox -and
        -not $script:UiLogTextBox.IsDisposed -and
        $script:UiLogTextBox.IsHandleCreated) {
      $script:UiLogTextBox.AppendText($line + [Environment]::NewLine)
      $script:UiLogTextBox.SelectionStart = $script:UiLogTextBox.Text.Length
      $script:UiLogTextBox.ScrollToCaret()
      $wroteToUi = $true
    }
  } catch {
    # If the UI control is gone, fall back to console output
  }

  if (-not $wroteToUi) {
    if ($IsError) {
      Write-Host $line -ForegroundColor Red
    } else {
      Write-Host $line
    }
  }
}

function Set-UiStatus {
  param(
    [string]$Text,
    [int]$Percent = -1
  )

  $wroteStatus = $false

  try {
    if ($script:UiStatusLabel -and
        -not $script:UiStatusLabel.IsDisposed -and
        $script:UiStatusLabel.IsHandleCreated) {
      $script:UiStatusLabel.Text = $Text
      $wroteStatus = $true
    }
  } catch {
    # Ignore UI errors and fall back to console
  }

  if (-not $wroteStatus) {
    Write-Host $Text
  }

  if ($Percent -ge 0) {
    try {
      if ($script:UiProgressBar -and
          -not $script:UiProgressBar.IsDisposed -and
          $script:UiProgressBar.IsHandleCreated) {
        $value = [Math]::Min([Math]::Max($Percent, $script:UiProgressBar.Minimum), $script:UiProgressBar.Maximum)
        $script:UiProgressBar.Value = $value
      }
    } catch {
      # Ignore progress bar errors
    }
  }

  try {
    [System.Windows.Forms.Application]::DoEvents()
  } catch {
    # Ignore DoEvents errors (for example, if the form is closing)
  }
}

function Throw-UiError {
  param(
    [string]$Message
  )

  Write-UiLog -Message $Message -IsError
  throw $Message
}

# --- Sub-progress helpers ----------------------------------------------------

function Show-SubProgress {
  param(
    [string]$Text = "",
    [switch]$Marquee
  )

  try {
    if ($script:UiSubStatusLabel -and -not $script:UiSubStatusLabel.IsDisposed) {
      $script:UiSubStatusLabel.Text    = $Text
      $script:UiSubStatusLabel.Visible = $true
    }
    if ($script:UiSubProgressBar -and -not $script:UiSubProgressBar.IsDisposed) {
      if ($Marquee) {
        $script:UiSubProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        $script:UiSubProgressBar.MarqueeAnimationSpeed = 30
      } else {
        $script:UiSubProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
        $script:UiSubProgressBar.Value = 0
      }
      $script:UiSubProgressBar.Visible = $true
    }
    [System.Windows.Forms.Application]::DoEvents()
  } catch { }
}

function Set-SubProgress {
  param(
    [string]$Text,
    [int]$Percent = -1
  )

  try {
    if ($Text -and $script:UiSubStatusLabel -and
        -not $script:UiSubStatusLabel.IsDisposed -and
        $script:UiSubStatusLabel.IsHandleCreated) {
      $script:UiSubStatusLabel.Text = $Text
    }
    if ($Percent -ge 0 -and $script:UiSubProgressBar -and
        -not $script:UiSubProgressBar.IsDisposed -and
        $script:UiSubProgressBar.IsHandleCreated) {
      if ($script:UiSubProgressBar.Style -ne [System.Windows.Forms.ProgressBarStyle]::Continuous) {
        $script:UiSubProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
      }
      $val = [Math]::Min([Math]::Max($Percent, 0), 100)
      $script:UiSubProgressBar.Value = $val
    }
    [System.Windows.Forms.Application]::DoEvents()
  } catch { }
}

function Hide-SubProgress {
  try {
    if ($script:UiSubStatusLabel -and -not $script:UiSubStatusLabel.IsDisposed) {
      $script:UiSubStatusLabel.Visible = $false
    }
    if ($script:UiSubProgressBar -and -not $script:UiSubProgressBar.IsDisposed) {
      $script:UiSubProgressBar.Visible = $false
      $script:UiSubProgressBar.Style   = [System.Windows.Forms.ProgressBarStyle]::Continuous
      $script:UiSubProgressBar.Value   = 0
    }
    [System.Windows.Forms.Application]::DoEvents()
  } catch { }
}

# --- Download helper with sub-progress bar -----------------------------------

function Invoke-DownloadWithProgress {
  param(
    [string]$Url,
    [string]$DestPath,
    [string]$Label = "Downloading..."
  )

  Show-SubProgress -Text $Label

  $webClient = New-Object System.Net.WebClient
  $script:downloadDone  = $false
  $script:downloadError = $null

  $webClient.Add_DownloadProgressChanged({
    param($sender, $e)
    try {
      $pct = $e.ProgressPercentage
      $mbDone  = [math]::Round($e.BytesReceived / 1MB, 1)
      $mbTotal = [math]::Round($e.TotalBytesToReceive / 1MB, 1)
      Set-SubProgress -Text "$Label  ${mbDone} / ${mbTotal} MB" -Percent $pct
    } catch { }
  })

  $webClient.Add_DownloadFileCompleted({
    param($sender, $e)
    if ($e.Error) { $script:downloadError = $e.Error }
    $script:downloadDone = $true
  })

  $webClient.DownloadFileAsync([Uri]$Url, $DestPath)

  while (-not $script:downloadDone) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 100
  }

  $webClient.Dispose()
  Hide-SubProgress

  if ($script:downloadError) {
    throw $script:downloadError
  }
}

# --- Run external process with live UI feedback and sub-progress -------------

function Invoke-ProcessWithUiOutput {
  param(
    [string]$FilePath,
    [string]$Arguments,
    [string]$WorkingDirectory,
    [string]$StatusText = "Running...",
    [switch]$ShowSubProgress
  )

  if ($ShowSubProgress) {
    Show-SubProgress -Text $StatusText -Marquee
  }

  $stderrFile = [System.IO.Path]::GetTempFileName()
  $stdoutFile = [System.IO.Path]::GetTempFileName()

  $proc = Start-Process -FilePath $FilePath -ArgumentList $Arguments `
            -WindowStyle Hidden -PassThru `
            -WorkingDirectory $WorkingDirectory `
            -RedirectStandardError $stderrFile `
            -RedirectStandardOutput $stdoutFile

  $lastStderrLen = 0
  $lastStdoutLen = 0
  $script:pullImagesDone  = 0
  $script:pullImagesTotal = 0

  while (-not $proc.HasExited) {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 500

    # Read new stderr lines (docker-compose writes progress here)
    try {
      $content = [System.IO.File]::ReadAllText($stderrFile)
      if ($content.Length -gt $lastStderrLen) {
        $newText = $content.Substring($lastStderrLen).Trim()
        $lastStderrLen = $content.Length
        if ($newText) {
          foreach ($rawLine in ($newText -split "`n")) {
            $l = $rawLine.Trim()
            if (-not $l) { continue }

            # Parse docker pull progress lines like "Image X Pulling" / "Image X Pulled"
            if ($ShowSubProgress) {
              if ($l -match 'Pulling\s*$') {
                $script:pullImagesTotal++
                Set-SubProgress -Text "$StatusText  $l"
              } elseif ($l -match 'Pulled\s*$' -or $l -match 'up to date') {
                $script:pullImagesDone++
                if ($script:pullImagesTotal -gt 0) {
                  $pct = [int]([math]::Min(($script:pullImagesDone / $script:pullImagesTotal) * 100, 100))
                  Set-SubProgress -Text "$StatusText  $l" -Percent $pct
                }
              } elseif ($l -match 'Creating\s*$' -or $l -match 'Starting\s*$') {
                Set-SubProgress -Text "$StatusText  $l"
              } elseif ($l -match 'Created\s*$' -or $l -match 'Started\s*$') {
                Set-SubProgress -Text "$StatusText  $l"
              } else {
                Set-SubProgress -Text "$StatusText  $l"
              }
            }

            Write-UiLog $l
          }
        }
      }
    } catch { }

    # Read new stdout lines
    try {
      $content = [System.IO.File]::ReadAllText($stdoutFile)
      if ($content.Length -gt $lastStdoutLen) {
        $newText = $content.Substring($lastStdoutLen).Trim()
        $lastStdoutLen = $content.Length
        if ($newText) {
          foreach ($line in ($newText -split "`n")) {
            $l = $line.Trim()
            if ($l) { Write-UiLog $l }
          }
        }
      }
    } catch { }
  }

  # Read any remaining output
  try {
    $remaining = [System.IO.File]::ReadAllText($stderrFile).Substring($lastStderrLen).Trim()
    if ($remaining) { foreach ($l in ($remaining -split "`n")) { $t = $l.Trim(); if ($t) { Write-UiLog $t } } }
  } catch { }
  try {
    $remaining = [System.IO.File]::ReadAllText($stdoutFile).Substring($lastStdoutLen).Trim()
    if ($remaining) { foreach ($l in ($remaining -split "`n")) { $t = $l.Trim(); if ($t) { Write-UiLog $t } } }
  } catch { }

  Remove-Item -Force $stderrFile -ErrorAction SilentlyContinue
  Remove-Item -Force $stdoutFile -ErrorAction SilentlyContinue

  if ($ShowSubProgress) {
    Hide-SubProgress
  }

  return $proc.ExitCode
}

# --- Core startup helpers (logic from the original script) -------------------

function Test-DockerInstalled {
  try {
    docker --version *>$null
    return $true
  } catch {
    return $false
  }
}

function Test-DockerDaemonRunning {
  try {
    docker info *>$null
    return $true
  } catch {
    return $false
  }
}

function Start-DockerDesktop {
  $candidatePaths = @(
    (Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Docker\Docker\Docker Desktop.exe"),
    (Join-Path $env:LocalAppData "Docker\Docker Desktop\Docker Desktop.exe"),
    (Join-Path $env:LocalAppData "Docker\Docker\Docker Desktop.exe"),
    (Join-Path $env:APPDATA "Docker\Docker Desktop.exe")
  ) | Where-Object { $_ -ne $null }

  # Also search any Docker* folders under ProgramFiles
  foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if ($base) {
      try {
        Get-ChildItem -LiteralPath $base -Directory -Filter "Docker*" -ErrorAction SilentlyContinue |
          ForEach-Object {
            $p = Join-Path $_.FullName "Docker Desktop.exe"
            if (Test-Path $p) { $candidatePaths += $p }
            $p2 = Join-Path $_.FullName "Docker\Docker Desktop.exe"
            if (Test-Path $p2) { $candidatePaths += $p2 }
          } | Out-Null
      } catch { }
    }
  }

  $dockerDesktopExe = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

  if (-not $dockerDesktopExe) {
    # Last resort: try to launch via the Start menu shortcut name
    Write-UiLog "Could not find Docker Desktop at a standard path; trying Start menu..."
    try {
      Start-Process "Docker Desktop" -ErrorAction Stop | Out-Null
      return $true
    } catch { }

    Write-UiLog "Could not find or start Docker Desktop automatically."
    Write-UiLog "Please start Docker Desktop yourself, then try again."
    return $false
  }

  Write-UiLog "Starting Docker Desktop ($dockerDesktopExe)..."
  Start-Process -FilePath $dockerDesktopExe | Out-Null
  return $true
}

function Wait-ForDockerDaemon {
  param(
    [int]$TimeoutSeconds = 300
  )

  $startTime = Get-Date
  while ((Get-Date) - $startTime -lt [TimeSpan]::FromSeconds($TimeoutSeconds)) {
    if (Test-DockerDaemonRunning) {
      return $true
    }
    Write-UiLog "Waiting for Docker Desktop to start..."
    Start-Sleep -Seconds 5
  }

  return $false
}

function Wait-ForPpaDesktop {
  param(
    [string]$Url = "http://localhost:8080/home",
    [int]$TimeoutSeconds = 300
  )

  $startTime = Get-Date
  while ((Get-Date) - $startTime -lt [TimeSpan]::FromSeconds($TimeoutSeconds)) {
    try {
      $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -MaximumRedirection 0 -Headers @{ "Cache-Control" = "no-cache"; "Pragma" = "no-cache" }
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
        return $true
      }
    } catch {
      $status = $null
      try { $status = $_.Exception.Response.StatusCode.value__ } catch { }
      if ($status -ge 200 -and $status -lt 400) {
        return $true
      }
    }

    Write-UiLog "Waiting for PPA Desktop to start at $Url ..."
    Start-Sleep -Seconds 5
  }

  return $false
}

function Get-InstalledPpaDesktopVersion {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AppRoot
  )

  $versionFile = Join-Path $AppRoot "version.txt"
  if (-not (Test-Path $versionFile)) {
    return $null
  }

  try {
    $content = Get-Content -Path $versionFile -ErrorAction Stop | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($content)) {
      return $null
    }
    return $content.Trim()
  } catch {
    return $null
  }
}

function Get-LatestPpaDesktopRelease {
  param(
    [string]$ApiUrl = "https://api.github.com/repos/kncvtbplus/ppa-desktop/releases/latest"
  )

  try {
    $headers = @{
      "User-Agent" = "PPA-Desktop-Updater"
      "Accept"     = "application/vnd.github+json"
    }

    $response = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -UseBasicParsing
    if (-not $response) {
      return $null
    }

    $tag = $response.tag_name
    if (-not $tag) {
      return $null
    }

    if ($tag -match '^v(.+)$') {
      $latestVersion = $matches[1]
    } else {
      $latestVersion = $tag
    }

    $asset = $null
    if ($response.assets) {
      # Prefer new PPA Desktop installer name, fall back to legacy PPA Wizard name
      $asset = $response.assets | Where-Object { $_.name -like 'ppa-desktop-setup-*.exe' } | Select-Object -First 1
      if (-not $asset) {
        $asset = $response.assets | Where-Object { $_.name -like 'ppa-wizard-setup-*.exe' } | Select-Object -First 1
      }
    }

    $downloadUrl = $null
    if ($asset -and $asset.browser_download_url) {
      $downloadUrl = $asset.browser_download_url
    }

    return [PSCustomObject]@{
      Version     = $latestVersion
      DownloadUrl = $downloadUrl
      ReleaseUrl  = $response.html_url
    }
  } catch {
    return $null
  }
}

function Compare-PpaDesktopVersion {
  param(
    [Parameter(Mandatory = $true)]
    [string]$A,
    [Parameter(Mandatory = $true)]
    [string]$B
  )

  # Returns -1 if A < B, 0 if A == B, 1 if A > B
  $aParts = $A.Split('.')
  $bParts = $B.Split('.')
  $max = [Math]::Max($aParts.Length, $bParts.Length)

  for ($i = 0; $i -lt $max; $i++) {
    $ai = if ($i -lt $aParts.Length) { [int]$aParts[$i] } else { 0 }
    $bi = if ($i -lt $bParts.Length) { [int]$bParts[$i] } else { 0 }

    if ($ai -lt $bi) { return -1 }
    if ($ai -gt $bi) { return 1 }
  }

  return 0
}

function Check-ForPpaDesktopUpdate {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AppRoot
  )

  Write-UiLog ""
  Write-UiLog "Checking for a newer PPA Desktop installer via kncvtbplus/ppa-desktop..."

  $installedVersion = Get-InstalledPpaDesktopVersion -AppRoot $AppRoot
  if (-not $installedVersion) {
    Write-UiLog "Could not determine installed PPA Desktop version (missing or empty version.txt); skipping update check."
    return $true
  }

  $latest = Get-LatestPpaDesktopRelease
  if (-not $latest -or -not $latest.Version) {
    Write-UiLog "Could not retrieve latest installer information from GitHub; skipping update check."
    return $true
  }

  try {
    $cmp = Compare-PpaDesktopVersion -A $installedVersion -B $latest.Version
  } catch {
    Write-UiLog "Could not compare installed version with latest release; skipping update check."
    return $true
  }

  if ($cmp -ge 0) {
    Write-UiLog ("PPA Desktop is up to date (installed {0}, latest {1})." -f $installedVersion, $latest.Version)
    return $true
  }

  Write-UiLog ""
  Write-UiLog "A newer PPA Desktop installer is available."
  Write-UiLog ("  Installed version: {0}" -f $installedVersion)
  Write-UiLog ("  Latest version:    {0}" -f $latest.Version)

  $question = "A newer PPA Desktop installer is available.`r`n`r`nInstalled version: $installedVersion`r`nLatest version: $($latest.Version)`r`n`r`nDownload and start the latest installer now?"
  $dialogResult = [System.Windows.Forms.MessageBox]::Show(
    $question,
    "PPA Desktop update available",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
  )

  if ($dialogResult -ne [System.Windows.Forms.DialogResult]::Yes) {
    Write-UiLog "Continuing with the currently installed version."
    return $true
  }

  if ($latest.DownloadUrl) {
    $tempDir = [System.IO.Path]::GetTempPath()
    # Try to derive a friendly filename from the download URL; fall back to a generic name
    $fileName = "ppa-desktop-setup-$($latest.Version).exe"
    if ($latest.DownloadUrl -match '/([^/]+)$') {
      $fileName = $matches[1]
    }
    $destPath = Join-Path $tempDir $fileName

    Write-UiLog "Downloading the latest installer to $destPath ..."
    try {
      Invoke-DownloadWithProgress -Url $latest.DownloadUrl -DestPath $destPath -Label "Downloading PPA Desktop $($latest.Version)..."
      Write-UiLog "Download complete. Starting the installer..."
      Start-Process -FilePath $destPath | Out-Null
      Write-UiLog "Follow the installer steps to upgrade PPA Desktop, then start it again from the Start menu."
      $script:ExitAfterUpdate = $true
      return $false
    } catch {
      Write-UiLog "Automatic download of the latest installer failed." -IsError
      if ($latest.ReleaseUrl) {
        Write-UiLog "Opening the release page in your browser instead..."
        Start-Process $latest.ReleaseUrl | Out-Null
        $script:ExitAfterUpdate = $true
        return $false
      }

      # If we cannot even open the release page, continue starting the current version
      Write-UiLog "Could not open the release page; continuing with the current version." -IsError
      return $true
    }
  } elseif ($latest.ReleaseUrl) {
    Write-UiLog "Opening the release page for the latest installer..." 
    Start-Process $latest.ReleaseUrl | Out-Null
    $script:ExitAfterUpdate = $true
    return $false
  }

  return $true
}

function Start-PpaDesktop {
  # 1. Docker Desktop presence and daemon
  Set-UiStatus "Checking Docker Desktop installation..." 5
  Write-UiLog "Checking whether Docker Desktop is installed..."

  if (-not (Test-DockerInstalled)) {
    Throw-UiError "Docker Desktop does not seem to be installed. Please install Docker Desktop for Windows first."
  }

  Set-UiStatus "Ensuring Docker Desktop is running..." 10

  if (-not (Test-DockerDaemonRunning)) {
    if (-not (Start-DockerDesktop)) {
      Throw-UiError "Docker Desktop is not running and could not be started automatically. Please start Docker Desktop yourself and run this shortcut again."
    }

    if (-not (Wait-ForDockerDaemon -TimeoutSeconds 300)) {
      Throw-UiError "Docker Desktop did not start in time. Please check Docker Desktop and try again."
    }

    Write-UiLog "Docker Desktop is now running."
  } else {
    Write-UiLog "Docker Desktop is already running."
  }

  # 2. Optional update check
  Set-UiStatus "Checking for PPA Desktop updates..." 25
  if (-not (Check-ForPpaDesktopUpdate -AppRoot $ProjectRoot)) {
    return
  }

  if ($script:ExitAfterUpdate) {
    return
  }

  # 3. Prepare local data directory used as /s3 mount
  Set-UiStatus "Preparing local data folders..." 35

  $LocalDataRoot = Join-Path $env:LOCALAPPDATA "PPA-Wizard"
  $S3LocalDir = Join-Path $LocalDataRoot "s3"
  if (-not (Test-Path $S3LocalDir)) {
    Write-UiLog "Creating local data directory for PPA Desktop at $S3LocalDir"
    New-Item -ItemType Directory -Path $S3LocalDir -Force | Out-Null
  }

  $S3ScriptDir     = Join-Path $S3LocalDir "script"
  $S3DatasourceDir = Join-Path $S3LocalDir "datasource"
  $S3OutputDir     = Join-Path $S3LocalDir "output"

  foreach ($dir in @($S3ScriptDir, $S3DatasourceDir, $S3OutputDir)) {
    if (-not (Test-Path $dir)) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
  }

  # 4. Seed/update the R script into the writable /s3 area
  Set-UiStatus "Copying PPA R script..." 45

  $BundledScript = Join-Path $ProjectRoot "local-dev\s3\script\Auto.PPA.UI.R"
  $TargetScript  = Join-Path $S3ScriptDir "Auto.PPA.UI.R"

  if (Test-Path $BundledScript) {
    Write-UiLog "Copying latest PPA R script to data directory ($TargetScript)..."
    Copy-Item $BundledScript $TargetScript -Force
  }

  # Expose this path to docker-compose so it can mount it as /s3 inside containers
  $env:PPA_DATA_DIR = $S3LocalDir

  # 5. Sanity check on application.jar
  Set-UiStatus "Checking application files..." 55

  if (-not (Test-Path (Join-Path $ProjectRoot "application.jar"))) {
    Throw-UiError "We could not find the main application file 'application.jar'. Please reinstall PPA Desktop or contact support."
  }

  # 6. Start docker-compose services
  Set-UiStatus "Downloading Docker images (if needed)..." 65

  Write-UiLog "Downloading the latest Docker images (this can take a few minutes the first time)..."
  Invoke-ProcessWithUiOutput -FilePath "docker-compose" -Arguments "pull" `
    -WorkingDirectory $ComposeDir -StatusText "Pulling images..." -ShowSubProgress

  Set-UiStatus "Starting PPA Desktop services..." 75
  Write-UiLog "Starting the PPA Desktop services..."
  Invoke-ProcessWithUiOutput -FilePath "docker-compose" -Arguments "up -d --force-recreate" `
    -WorkingDirectory $ComposeDir -StatusText "Starting services..." -ShowSubProgress

  # 7. Wait for the app to respond and open it
  $HealthUrl = "http://localhost:8080/home"
  $AppUrl    = "http://localhost:8080"
  Set-UiStatus "Waiting for PPA Desktop to respond..." 85
  Write-UiLog "Waiting for PPA Desktop to start..."

  if (Wait-ForPpaDesktop -Url $HealthUrl -TimeoutSeconds 300) {
    Write-UiLog "PPA Desktop is ready. Opening it in your browser at $AppUrl"
    Start-Process $AppUrl | Out-Null
  } else {
    Write-UiLog "PPA Desktop did not start within the expected time. You can still try opening $AppUrl in your browser." -IsError
    Start-Process $AppUrl | Out-Null
  }

  Set-UiStatus "PPA Desktop has started." 100
}

$form.Add_Shown({
  param($sender, $eventArgs)

  $script:UiForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  Set-UiStatus "Starting PPA Desktop..." 0
  Write-UiLog "Starting PPA Desktop and its background services..."

  try {
    Start-PpaDesktop

    $script:UiForm.Cursor = [System.Windows.Forms.Cursors]::Default
    $script:UiCloseButton.Enabled = $true

    if ($script:ExitAfterUpdate) {
      Set-UiStatus "PPA Desktop update started." 100
      Write-UiLog "The installer has been started. This window will close automatically."

      $timer = New-Object System.Windows.Forms.Timer
      $timer.Interval = 2000
      $timer.Add_Tick({
        param($sender, $eventArgs)
        try { $sender.Stop() } catch { }
        try { if ($script:UiForm -ne $null -and -not $script:UiForm.IsDisposed) { $script:UiForm.Close() } } catch { }
      })
      $timer.Start()
      return
    }

    Write-UiLog "PPA Desktop is ready. This window will close automatically in a few seconds."

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 4000
    $timer.Add_Tick({
      param($sender, $eventArgs)

      try {
        if ($sender -ne $null) {
          $sender.Stop()
        }
      } catch {
        # Ignore timer stop errors
      }

      try {
        if ($script:UiForm -ne $null -and -not $script:UiForm.IsDisposed) {
          $script:UiForm.Close()
        }
      } catch {
        # Ignore close errors; form may already be closing/closed
      }
    })
    $timer.Start()
  } catch {
    $script:UiForm.Cursor = [System.Windows.Forms.Cursors]::Default
    $script:UiCloseButton.Enabled = $true

    $errorMessage = $_.Exception.Message
    Set-UiStatus $errorMessage 0
    Write-UiLog "Error: $errorMessage" -IsError

    if ($_.InvocationInfo -ne $null -and $_.InvocationInfo.PositionMessage) {
      Write-UiLog $_.InvocationInfo.PositionMessage -IsError
    }
  }
})

[System.Windows.Forms.Application]::Run($form)

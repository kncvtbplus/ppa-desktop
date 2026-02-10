$ErrorActionPreference = 'Stop'

# Keep the window open and show a clear message if anything goes wrong
trap {
  Write-Host ""
  Write-Host "Something went wrong while starting PPA Desktop:" -ForegroundColor Red
  if ($_.InvocationInfo -ne $null) {
    Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor Yellow
  }
  Write-Host $_.Exception.Message -ForegroundColor Red
  Write-Host ""
  Read-Host "Press Enter to close this window"
  exit 1
}

Write-Host "Starting PPA Desktop and its background services..." -ForegroundColor Cyan

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
  # Common install locations for Docker Desktop
  $candidatePaths = @(
    (Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Docker\Docker\Docker Desktop.exe"),
    (Join-Path $env:LocalAppData "Docker\Docker\Docker Desktop.exe")
  ) | Where-Object { $_ -ne $null }

  $dockerDesktopExe = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

  if (-not $dockerDesktopExe) {
    Write-Warning "We could not find Docker Desktop automatically. Please start Docker Desktop yourself."
    return $false
  }

  Write-Host "Docker Desktop is not running; starting it now..." -ForegroundColor Yellow
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
    Write-Host "Waiting for Docker Desktop to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
  }

  return $false
}

function Wait-ForPpaDesktop {
  param(
    [string]$Url = "http://localhost:8080",
    [int]$TimeoutSeconds = 300
  )

  $startTime = Get-Date
  while ((Get-Date) - $startTime -lt [TimeSpan]::FromSeconds($TimeoutSeconds)) {
    try {
      $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache"; "Pragma" = "no-cache" }
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
        return $true
      }
    } catch {
      # Service not up yet; ignore and keep waiting
    }

    Write-Host "Waiting for PPA Desktop to start at $Url ..." -ForegroundColor Yellow
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

  $installedVersion = Get-InstalledPpaDesktopVersion -AppRoot $AppRoot
  if (-not $installedVersion) {
    return
  }

  $latest = Get-LatestPpaDesktopRelease
  if (-not $latest -or -not $latest.Version) {
    return
  }

  try {
    $cmp = Compare-PpaDesktopVersion -A $installedVersion -B $latest.Version
  } catch {
    return
  }

  if ($cmp -ge 0) {
    return
  }

  Write-Host ""
  Write-Host "A newer PPA Desktop installer is available." -ForegroundColor Yellow
  Write-Host ("  Installed version: {0}" -f $installedVersion)
  Write-Host ("  Latest version:    {0}" -f $latest.Version)

  $answer = Read-Host "Open the download page for the latest installer now? (Y/N)"
  if ($answer -match '^(Y|y|J|j)$') {
    $url = $latest.DownloadUrl
    if (-not $url) {
      $url = $latest.ReleaseUrl
    }

    if ($url) {
      Write-Host "Opening the latest PPA Desktop release in your browser..." -ForegroundColor Cyan
      Start-Process $url
      Write-Host "After installing the new version, please start PPA Desktop again from the Start menu." -ForegroundColor Cyan
      Read-Host "Press Enter to close this window"
      exit 0
    }
  }
}

if (-not (Test-DockerInstalled)) {
  Write-Error "Docker Desktop does not seem to be installed. Please install Docker Desktop for Windows first."
  Read-Host "Press Enter to close this window"
  exit 1
}

# Make sure Docker Desktop is running; if not, try to start it
if (-not (Test-DockerDaemonRunning)) {
  if (-not (Start-DockerDesktop)) {
    Write-Error "Docker Desktop is not running and could not be started automatically. Please start Docker Desktop yourself and run this shortcut again."
    Read-Host "Press Enter to close this window"
    exit 1
  }

  if (-not (Wait-ForDockerDaemon -TimeoutSeconds 300)) {
    Write-Error "Docker Desktop did not start in time. Please check Docker Desktop and try again."
    Read-Host "Press Enter to close this window"
    exit 1
  }

  Write-Host "Docker Desktop is now running." -ForegroundColor Green
} else {
  Write-Host "Docker Desktop is already running." -ForegroundColor Green
}

# Determine script location and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ComposeDir = Join-Path $ProjectRoot "local-dev"

# Check if a newer PPA Desktop installer is available and offer to open the download page
Check-ForPpaDesktopUpdate -AppRoot $ProjectRoot

# Determine a user-writable data directory for Docker volumes (e.g. /s3 mount)
$LocalDataRoot = Join-Path $env:LOCALAPPDATA "PPA-Wizard"
$S3LocalDir = Join-Path $LocalDataRoot "s3"
if (-not (Test-Path $S3LocalDir)) {
  Write-Host "Creating local data directory for PPA Desktop at $S3LocalDir" -ForegroundColor Cyan
  New-Item -ItemType Directory -Path $S3LocalDir -Force | Out-Null
}

# Ensure subfolders exist for script, datasource, and output under the shared /s3 mount
$S3ScriptDir     = Join-Path $S3LocalDir "script"
$S3DatasourceDir = Join-Path $S3LocalDir "datasource"
$S3OutputDir     = Join-Path $S3LocalDir "output"

foreach ($dir in @($S3ScriptDir, $S3DatasourceDir, $S3OutputDir)) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
}

# Seed/update the R script into the writable /s3 area every time
$BundledScript = Join-Path $ProjectRoot "local-dev\s3\script\Auto.PPA.UI.R"
$TargetScript  = Join-Path $S3ScriptDir "Auto.PPA.UI.R"

if (Test-Path $BundledScript) {
  Write-Host "Copying latest PPA R script to data directory ($TargetScript)..." -ForegroundColor Cyan
  Copy-Item $BundledScript $TargetScript -Force
}

# Expose this path to docker-compose so it can mount it as /s3 inside containers
$env:PPA_DATA_DIR = $S3LocalDir

if (-not (Test-Path (Join-Path $ProjectRoot "application.jar"))) {
  Write-Error "We could not find the main application file 'application.jar'. Please reinstall PPA Desktop or contact support."
  Read-Host "Press Enter to close this window"
  exit 1
}

Push-Location $ComposeDir
try {
  Write-Host "Downloading the latest PPA Desktop Docker images (this needs internet the first time)..." -ForegroundColor Yellow
  docker-compose pull

  Write-Host "Starting the PPA Desktop services (this can take a few minutes the first time)..." -ForegroundColor Yellow
  docker-compose up -d
} finally {
  Pop-Location
}

${AppUrl} = "http://localhost:8080"
Write-Host "Waiting for PPA Desktop to start..." -ForegroundColor Yellow

if (Wait-ForPpaDesktop -Url $AppUrl -TimeoutSeconds 300) {
  Write-Host "PPA Desktop is ready. Opening it in your browser at $AppUrl" -ForegroundColor Green
  Start-Process $AppUrl
} else {
  Write-Warning "PPA Desktop did not start within the expected time. You can still try opening $AppUrl in your browser."
  Start-Process $AppUrl
}

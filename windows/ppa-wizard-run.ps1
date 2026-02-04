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

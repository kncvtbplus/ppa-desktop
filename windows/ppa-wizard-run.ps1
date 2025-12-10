$ErrorActionPreference = 'Stop'

Write-Host "Starting PPA Wizard (Docker stack)..." -ForegroundColor Cyan

function Test-DockerInstalled {
  try {
    docker --version *>$null
    return $true
  } catch {
    return $false
  }
}

if (-not (Test-DockerInstalled)) {
  Write-Error "Docker Desktop is not installed or not available in PATH. Please install Docker Desktop for Windows first."
  exit 1
}

# Determine script location and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ComposeDir = Join-Path $ProjectRoot "local-dev"

# Determine a user-writable data directory for Docker volumes (e.g. /s3 mount)
$LocalDataRoot = Join-Path $env:LOCALAPPDATA "PPA-Wizard"
$S3LocalDir = Join-Path $LocalDataRoot "s3"

if (-not (Test-Path $S3LocalDir)) {
  Write-Host "Creating local data directory for PPA Wizard at $S3LocalDir" -ForegroundColor Cyan
  New-Item -ItemType Directory -Path $S3LocalDir -Force | Out-Null
}

# Expose this path to docker-compose so it can mount it as /s3 inside containers
$env:PPA_DATA_DIR = $S3LocalDir

if (-not (Test-Path (Join-Path $ProjectRoot "application.jar"))) {
  Write-Error "Could not find 'application.jar' in project root ($ProjectRoot). Make sure the application JAR is present."
  exit 1
}

if (-not (Test-Path (Join-Path $ComposeDir "docker-compose.yml"))) {
  Write-Error "Could not find 'local-dev/docker-compose.yml'."
  exit 1
}

function Initialize-DatabaseIfNeeded {
  param(
    [string]$ProjectRoot
  )

  $markerPath = Join-Path $ProjectRoot "windows\db_initialized.flag"
  if (Test-Path $markerPath) {
    Write-Host "Database already initialized (marker file found)." -ForegroundColor DarkGreen
    return
  }

  $dumpPath = Join-Path $ProjectRoot "ppa-20251113153524.dump"
  $restoreScript = Join-Path $ProjectRoot "scripts\restore_local.ps1"

  if (-not (Test-Path $dumpPath)) {
    Write-Host "No initial database dump found at $dumpPath. Skipping automatic restore." -ForegroundColor Yellow
    return
  }

  if (-not (Test-Path $restoreScript)) {
    Write-Host "Restore script not found at $restoreScript. Skipping automatic restore." -ForegroundColor Yellow
    return
  }

  Write-Host "Initializing PPA database from dump (one-time operation)..." -ForegroundColor Yellow
  try {
    & $restoreScript -DumpPath $dumpPath
    New-Item -ItemType File -Path $markerPath -Force | Out-Null
    Write-Host "Database initialization completed." -ForegroundColor Green
  } catch {
    Write-Warning "Database initialization failed: $($_.Exception.Message)"
  }
}

Push-Location $ComposeDir
try {
  Write-Host "Bringing up Docker services (this may take a while the first time)..." -ForegroundColor Yellow
  docker-compose up -d --build
} finally {
  Pop-Location
}

# Give containers some time to start
Start-Sleep -Seconds 10

# Initialize database on first run if needed
Initialize-DatabaseIfNeeded -ProjectRoot $ProjectRoot

Write-Host "Opening PPA Wizard in the default browser at http://localhost:8080" -ForegroundColor Green
Start-Process "http://localhost:8080"


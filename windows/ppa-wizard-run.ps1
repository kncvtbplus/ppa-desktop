$ErrorActionPreference = 'Stop'

# Keep the window open and show a clear message if anything goes wrong
trap {
  Write-Host ""
  Write-Host "An unexpected error occurred while starting PPA Wizard:" -ForegroundColor Red
  if ($_.InvocationInfo -ne $null) {
    Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor Yellow
  }
  Write-Host $_.Exception.Message -ForegroundColor Red
  Write-Host ""
  Read-Host "Press Enter to close this window"
  exit 1
}

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
  Read-Host "Press Enter to close this window"
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
  Write-Error "Could not find 'application.jar' in project root ($ProjectRoot). Make sure the application JAR is present."
  Read-Host "Press Enter to close this window"
  exit 1
}

Push-Location $ComposeDir
try {
  Write-Host "Bringing up Docker services (this may take a while the first time)..." -ForegroundColor Yellow
  docker-compose up -d --build
} finally {
  Pop-Location
}

Write-Host "Opening PPA Wizard in the default browser at http://localhost:8080" -ForegroundColor Green
Start-Process "http://localhost:8080"

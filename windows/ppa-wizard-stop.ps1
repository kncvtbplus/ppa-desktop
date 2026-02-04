$ErrorActionPreference = 'Stop'

Write-Host "Stopping PPA Desktop and its background services..." -ForegroundColor Cyan

function Test-DockerInstalled {
  try {
    docker --version *>$null
    return $true
  } catch {
    return $false
  }
}

if (-not (Test-DockerInstalled)) {
  Write-Error "Docker Desktop does not seem to be installed."
  exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ComposeDir = Join-Path $ProjectRoot "local-dev"

if (-not (Test-Path (Join-Path $ComposeDir "docker-compose.yml"))) {
  Write-Error "Could not find the file 'local-dev/docker-compose.yml'. Please reinstall PPA Desktop or contact support."
  exit 1
}

Push-Location $ComposeDir
try {
  docker-compose down
} finally {
  Pop-Location
}

Write-Host "PPA Desktop has been stopped." -ForegroundColor Green






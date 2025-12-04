$ErrorActionPreference = 'Stop'

Write-Host "Stopping PPA Wizard (Docker stack)..." -ForegroundColor Cyan

function Test-DockerInstalled {
  try {
    docker --version *>$null
    return $true
  } catch {
    return $false
  }
}

if (-not (Test-DockerInstalled)) {
  Write-Error "Docker Desktop is not installed or not available in PATH."
  exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ComposeDir = Join-Path $ProjectRoot "local-dev"

if (-not (Test-Path (Join-Path $ComposeDir "docker-compose.yml"))) {
  Write-Error "Could not find 'local-dev/docker-compose.yml'."
  exit 1
}

Push-Location $ComposeDir
try {
  docker-compose down
} finally {
  Pop-Location
}

Write-Host "PPA Wizard stack stopped." -ForegroundColor Green





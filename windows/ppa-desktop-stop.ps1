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

function Get-RunningDockerContainers {
  try {
    $output = docker ps -q
    if ([string]::IsNullOrWhiteSpace($output)) {
      return @()
    }
    return $output -split '\s+'
  } catch {
    return @()
  }
}

function Stop-DockerDesktop {
  $stoppedAny = $false
  $processNames = @(
    "Docker Desktop",
    "com.docker.backend",
    "com.docker.proxy"
  )

  foreach ($name in $processNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
      Write-Host "Stopping process '$name'..." -ForegroundColor Cyan
      foreach ($p in $procs) {
        try {
          Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
          $stoppedAny = $true
        } catch {
          # Ignore individual process stop failures
        }
      }
    }
  }

  if ($stoppedAny) {
    Write-Host "Docker Desktop has been stopped." -ForegroundColor Green
  } else {
    Write-Host "Docker Desktop does not appear to be running (no Docker Desktop processes found)." -ForegroundColor Yellow
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

Write-Host "PPA Desktop containers have been stopped." -ForegroundColor Green

# If there are no other running Docker containers, stop Docker Desktop itself
$remainingContainers = Get-RunningDockerContainers
if ($remainingContainers.Count -eq 0) {
  Write-Host "No other running Docker containers detected; stopping Docker Desktop..." -ForegroundColor Cyan
  Stop-DockerDesktop
} else {
  Write-Host "Other Docker containers are still running; Docker Desktop will remain running." -ForegroundColor Yellow
}

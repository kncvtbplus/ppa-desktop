$ErrorActionPreference = 'Stop'

# Thin wrapper to stop PPA Desktop using the main script
# that still uses the legacy 'ppa-wizard' file name.

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LegacyScript = Join-Path $ScriptDir 'ppa-wizard-stop.ps1'

if (-not (Test-Path $LegacyScript)) {
  Write-Host ""
  Write-Host "Could not find the main stop script 'ppa-wizard-stop.ps1'." -ForegroundColor Red
  Write-Host "Please reinstall PPA Desktop or contact support." -ForegroundColor Red
  Write-Host ""
  Read-Host "Press Enter to close this window"
  exit 1
}

& $LegacyScript

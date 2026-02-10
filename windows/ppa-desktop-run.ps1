$ErrorActionPreference = 'Stop'

# Thin wrapper to start PPA Desktop using the main script
# that still uses the legacy 'ppa-wizard' file name.

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LegacyScript = Join-Path $ScriptDir 'ppa-wizard-run.ps1'

if (-not (Test-Path $LegacyScript)) {
  Write-Host ""
  Write-Host "Could not find the main startup script 'ppa-wizard-run.ps1'." -ForegroundColor Red
  Write-Host "Please reinstall PPA Desktop or contact support." -ForegroundColor Red
  Write-Host ""
  Read-Host "Press Enter to close this window"
  exit 1
}

& $LegacyScript

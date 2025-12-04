$ErrorActionPreference = 'Stop'
param(
  [Parameter(Mandatory=$true)]
  [string]$DumpPath,             # Path to .dump (custom format) or .sql
  [string]$DbName = "ppa",
  [string]$DbUser = "ppa",
  [string]$DbPassword = "Automation",
  [string]$DbHost = "localhost",
  [int]$DbPort = 5432
)

function Use-Docker() {
  try {
    $v = (docker --version) 2>$null
    return -not [string]::IsNullOrWhiteSpace($v)
  } catch { return $false }
}

if (!(Test-Path $DumpPath)) { throw "File not found: $DumpPath" }

if (Use-Docker) {
  Write-Host "Using Docker-based restore into postgres container (ppa-postgres-local)"
  $container = "ppa-postgres-local"
  # Create DB if needed
  docker exec $container bash -lc "psql -U $DbUser -d postgres -tc \"SELECT 1 FROM pg_database WHERE datname='$DbName'\" | grep -q 1 || createdb -U $DbUser $DbName"
  # Copy dump into container
  $target = "/tmp/restore.dump"
  docker cp $DumpPath ${container}:$target
  # Determine type by extension
  if ($DumpPath.ToLower().EndsWith('.dump')) {
    docker exec $container bash -lc "pg_restore -U $DbUser -d $DbName --clean --if-exists -O -x $target"
  } else {
    docker exec $container bash -lc "psql -U $DbUser -d $DbName -f $target"
  }
  docker exec $container rm -f $target | Out-Null
  Write-Host "Restore complete."
} else {
  Write-Host "Docker not found. Attempting native pg_restore/psql on host."
  if ($DumpPath.ToLower().EndsWith('.dump')) {
    $env:PGPASSWORD = $DbPassword
    & pg_restore -h $DbHost -p $DbPort -U $DbUser -d $DbName --clean --if-exists -O -x $DumpPath
  } else {
    $env:PGPASSWORD = $DbPassword
    & psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $DumpPath
  }
  Write-Host "Restore complete."
}





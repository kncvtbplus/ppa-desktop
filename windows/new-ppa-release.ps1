<#
    new-ppa-release.ps1

    Single-entry workflow to:
    - Build application.jar from source via Maven
    - Build and push the Docker image to Docker Hub (--no-cache)
    - Update the root version.txt
    - Update the Inno Setup (.iss) script with the new version and output name
    - Build the Windows installer with Inno Setup
    - Publish the installer, version.txt and key docs to the GitHub
      "distribution" repository via publish-installer.ps1

    Usage (from repo root):

        pwsh .\windows\new-ppa-release.ps1 -Version 1.6.0

    Optional:

        pwsh .\windows\new-ppa-release.ps1 -Version 1.6.0 `
            -DistributionRepo "your-org/your-distribution-repo"

    Requirements
    ------------
    - Inno Setup 6 installed with ISCC.exe available either on PATH or at a
      standard location (e.g. "C:\Program Files (x86)\Inno Setup 6\ISCC.exe").
    - Docker Desktop installed and running (for Docker image build/push).
    - GitHub CLI installed and authenticated (`gh auth login`) for the
      distribution repository.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    # GitHub "distribution" repository (owner/repo) to publish to.
    [string]$DistributionRepo = "kncvtbplus/ppa-desktop",

    # Optional explicit path to ISCC.exe (Inno Setup compiler).
    [string]$IsccPath,

    # Build everything but do not publish to GitHub releases.
    [switch]$SkipPublish,

    # Skip Docker image build and push.
    [switch]$SkipDocker
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    # NOTE: Inside a function, $MyInvocation.MyCommand is the *function*, not the script.
    # Use $PSScriptRoot / $PSCommandPath to locate this file reliably.
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
    $repoRoot = (Get-Item -LiteralPath (Join-Path $scriptDir "..") -ErrorAction Stop).FullName

    if (-not $repoRoot) {
        throw "Could not resolve repository root from script location."
    }

    return $repoRoot
}

function Get-InnoSetupCompilerPath {
    param(
        [string]$PreferredPath
    )

    if ($PreferredPath) {
        if (-not (Test-Path -LiteralPath $PreferredPath)) {
            # Don't immediately fail; fall back to auto-detection.
            Write-Warning "ISCC.exe not found at the provided -IsccPath '$PreferredPath'. Trying auto-detection..."
        }
        else {
            return (Resolve-Path -LiteralPath $PreferredPath -ErrorAction Stop).Path
        }
    }

    # First try to find ISCC.exe on PATH
    $cmd = Get-Command iscc -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    # PATH (where.exe) sometimes finds iscc.exe even when Get-Command doesn't
    try {
        $where = & where.exe ISCC.exe 2>$null
        if ($where) {
            $candidate = ($where | Select-Object -First 1)
            if ($candidate -and (Test-Path -LiteralPath $candidate)) {
                return (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path
            }
        }
    } catch {
        # ignore
    }

    # Try registry: App Paths
    $appPathKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ISCC.exe',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\ISCC.exe'
    )

    foreach ($key in $appPathKeys) {
        try {
            if (Test-Path $key) {
                $item = Get-Item -LiteralPath $key -ErrorAction Stop
                $defaultValue = $item.GetValue('')
                if ($defaultValue -and (Test-Path -LiteralPath $defaultValue)) {
                    return (Resolve-Path -LiteralPath $defaultValue -ErrorAction Stop).Path
                }
            }
        } catch {
            # ignore and continue
        }
    }

    # Try registry: Uninstall keys with InstallLocation
    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 5_is1',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 5_is1'
    )

    foreach ($key in $uninstallKeys) {
        try {
            if (Test-Path $key) {
                $props = Get-ItemProperty -LiteralPath $key -ErrorAction Stop
                if ($props.InstallLocation) {
                    $candidate = Join-Path $props.InstallLocation 'ISCC.exe'
                    if (Test-Path -LiteralPath $candidate) {
                        return (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path
                    }
                }
            }
        } catch {
            # ignore and continue
        }
    }

    # Fallback to some common install locations
    $candidates = @()

    if (${env:ProgramFiles(x86)}) {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe")
    }

    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
    }

    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe")
    }

    # Chocolatey / Scoop common shims
    $candidates += @(
        "C:\ProgramData\chocolatey\bin\iscc.exe",
        "C:\ProgramData\chocolatey\bin\ISCC.exe"
    )

    if ($env:USERPROFILE) {
        $candidates += (Join-Path $env:USERPROFILE "scoop\apps\innosetup\current\ISCC.exe")
    }

    # Light directory scan for "Inno Setup*" folders (fast, shallow)
    foreach ($base in @(${env:ProgramFiles(x86)}, $env:ProgramFiles, (Join-Path $env:LOCALAPPDATA "Programs"))) {
        if (-not $base) { continue }
        try {
            Get-ChildItem -LiteralPath $base -Directory -Filter "Inno Setup*" -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $p = Join-Path $_.FullName "ISCC.exe"
                    if (Test-Path -LiteralPath $p) {
                        $candidates += $p
                    }
                } | Out-Null
        } catch {
            # ignore
        }
    }

    $compiler = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $compiler) {
        $checked = ($candidates | Select-Object -Unique) -join "`n  - "
        throw @"
Could not find Inno Setup compiler 'ISCC.exe'.

Fix options:
  - Install Inno Setup (WinGet): winget install JRSoftware.InnoSetup
  - Or pass the full path: -IsccPath "C:\Path\To\ISCC.exe"

Paths checked:
  - $checked
"@
    }

    return $compiler
}

function Build-ApplicationJar {
    param(
        [string]$RepoRoot
    )

    $sourceDir = Join-Path $RepoRoot "PPA sourcecode\project\PPA"
    $mvnw = Join-Path $sourceDir "mvnw.cmd"

    if (-not (Test-Path -LiteralPath $mvnw)) {
        throw "Maven wrapper not found at '$mvnw'. Cannot build application.jar automatically."
    }

    Write-Host "Building application.jar from source (this can take a while on first run)..." -ForegroundColor Cyan

    Push-Location $sourceDir
    try {
        & $mvnw -DskipTests package
        if ($LASTEXITCODE -ne 0) {
            throw "Maven build failed with exit code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }

    $builtJar = Join-Path $sourceDir "target\application.jar"
    if (-not (Test-Path -LiteralPath $builtJar)) {
        throw "Maven build succeeded but '$builtJar' was not found."
    }

    $destJar = Join-Path $RepoRoot "application.jar"
    Copy-Item -LiteralPath $builtJar -Destination $destJar -Force
    Write-Host "application.jar updated at: $destJar" -ForegroundColor Green
}

function Update-VersionFiles {
    param(
        [string]$RepoRoot,
        [string]$Version
    )

    $versionFilePath = Join-Path $RepoRoot "version.txt"
    if (-not (Test-Path $versionFilePath)) {
        throw "version.txt not found at '$versionFilePath'."
    }

    Write-Host "Updating version.txt to $Version..." -ForegroundColor Cyan
    Set-Content -Path $versionFilePath -Value $Version -Encoding UTF8
}

function Update-InnoSetupScript {
    param(
        [string]$WindowsDir,
        [string]$Version
    )

    $issPath = Join-Path $WindowsDir "ppa-desktop-installer.iss"
    if (-not (Test-Path $issPath)) {
        throw "Inno Setup script not found at '$issPath'."
    }

    Write-Host "Updating Inno Setup script with version $Version..." -ForegroundColor Cyan

    $content = Get-Content -Path $issPath

    $content = $content -replace '^AppVersion=.*$', "AppVersion=$Version"
    $content = $content -replace '^OutputBaseFilename=.*$', "OutputBaseFilename=ppa-desktop-setup-$Version"

    Set-Content -Path $issPath -Value $content -Encoding UTF8
}

function Build-Installer {
    param(
        [string]$WindowsDir,
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$CompilerPath
    )

    Write-Host "Using Inno Setup compiler at: $CompilerPath" -ForegroundColor Cyan

    Push-Location $WindowsDir
    try {
        Write-Host "Building installer for version $Version..." -ForegroundColor Cyan
        & $CompilerPath "ppa-desktop-installer.iss"

        if ($LASTEXITCODE -ne 0) {
            throw "Inno Setup compiler failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }

    $expectedExe = Join-Path $WindowsDir ("ppa-desktop-setup-{0}.exe" -f $Version)
    if (-not (Test-Path $expectedExe)) {
        throw "Expected installer '$expectedExe' was not found after compilation."
    }

    Write-Host "Installer built: $expectedExe" -ForegroundColor Green
}

function Ensure-GitHubCliAvailable {
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    $ghExe = $null

    if ($cmd -and $cmd.Source) {
        $ghExe = $cmd.Source
    } else {
        $candidates = @()

        if ($env:ProgramFiles) {
            $candidates += (Join-Path $env:ProgramFiles "GitHub CLI\gh.exe")
            $candidates += (Join-Path $env:ProgramFiles "GitHub CLI\bin\gh.exe")
        }

        if (${env:ProgramFiles(x86)}) {
            $candidates += (Join-Path ${env:ProgramFiles(x86)} "GitHub CLI\gh.exe")
            $candidates += (Join-Path ${env:ProgramFiles(x86)} "GitHub CLI\bin\gh.exe")
        }

        if ($env:LOCALAPPDATA) {
            $candidates += (Join-Path $env:LOCALAPPDATA "Programs\GitHub CLI\gh.exe")
            $candidates += (Join-Path $env:LOCALAPPDATA "Programs\GitHub CLI\bin\gh.exe")
        }

        $ghExe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($ghExe) {
            $ghExe = (Resolve-Path -LiteralPath $ghExe -ErrorAction Stop).Path
        }
    }

    if (-not $ghExe) {
        throw @"
GitHub CLI ('gh') was not found on this system.

Install options:
  - WinGet: winget install -e --id GitHub.cli

After installing, run:
  gh auth login

Then rerun this script.
"@
    }

    & $ghExe auth status -h github.com *> $null
    if ($LASTEXITCODE -ne 0) {
        throw @"
GitHub CLI is installed but not authenticated for github.com.

Run:
  `"$ghExe`" auth login

Then rerun this script.
"@
    }
}

function Build-DockerImage {
    param(
        [string]$RepoRoot,
        [string]$Version
    )

    $dockerfile = Join-Path $RepoRoot "Dockerfile"
    if (-not (Test-Path $dockerfile)) {
        throw "Dockerfile not found at '$dockerfile'."
    }

    $imageBase = "kncvtbplus/ppa-app"
    $tagVersion = "${imageBase}:${Version}"
    $tagLatest  = "${imageBase}:latest"

    Write-Host "Building Docker image $tagVersion (--no-cache)..." -ForegroundColor Cyan
    Push-Location $RepoRoot
    try {
        & docker build --no-cache -t $tagVersion -f Dockerfile .
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed with exit code $LASTEXITCODE."
        }

        docker tag $tagVersion $tagLatest
        Write-Host "Docker image built and tagged as $tagVersion and $tagLatest." -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Push-DockerImage {
    param(
        [string]$Version
    )

    $imageBase = "kncvtbplus/ppa-app"
    $tagVersion = "${imageBase}:${Version}"
    $tagLatest  = "${imageBase}:latest"

    Write-Host "Pushing Docker image $tagVersion to Docker Hub..." -ForegroundColor Cyan
    & docker push $tagVersion
    if ($LASTEXITCODE -ne 0) {
        throw "Docker push of $tagVersion failed with exit code $LASTEXITCODE."
    }

    Write-Host "Pushing Docker image $tagLatest to Docker Hub..." -ForegroundColor Cyan
    & docker push $tagLatest
    if ($LASTEXITCODE -ne 0) {
        throw "Docker push of $tagLatest failed with exit code $LASTEXITCODE."
    }

    Write-Host "Docker images pushed successfully." -ForegroundColor Green
}

function Publish-Installer {
    param(
        [string]$WindowsDir,
        [string]$Version,
        [string]$DistributionRepo
    )

    $publishScript = Join-Path $WindowsDir "publish-installer.ps1"
    if (-not (Test-Path $publishScript)) {
        throw "Publish script not found at '$publishScript'."
    }

    Write-Host "Publishing installer and related files to $DistributionRepo..." -ForegroundColor Cyan
    & $publishScript -Version $Version -DistributionRepo $DistributionRepo
}

try {
    $repoRoot = Resolve-RepoRoot
    $windowsDir = Join-Path $repoRoot "windows"

    if (-not (Test-Path $windowsDir)) {
        throw "Windows directory not found at '$windowsDir'."
    }

    Write-Host "Repository root: $repoRoot" -ForegroundColor DarkGray

    # Preflight: fail early before mutating version files if tooling is missing.
    $compilerPath = Get-InnoSetupCompilerPath -PreferredPath $IsccPath
    if (-not $SkipPublish) {
        Ensure-GitHubCliAvailable
    }

    # Ensure we have a fresh application.jar at repo root (required by the .iss script)
    Build-ApplicationJar -RepoRoot $repoRoot

    # Build and push the Docker image so PPA Desktop users get the updated app.
    # Uses --no-cache to guarantee the freshly built JAR is included.
    if (-not $SkipDocker) {
        Build-DockerImage -RepoRoot $repoRoot -Version $Version
        Push-DockerImage -Version $Version
    }

    Update-VersionFiles -RepoRoot $repoRoot -Version $Version
    Update-InnoSetupScript -WindowsDir $windowsDir -Version $Version
    Build-Installer -WindowsDir $windowsDir -Version $Version -CompilerPath $compilerPath
    if (-not $SkipPublish) {
        Publish-Installer -WindowsDir $windowsDir -Version $Version -DistributionRepo $DistributionRepo
    }

    Write-Host ""
    if ($SkipPublish) {
        Write-Host "Successfully built PPA Desktop version $Version (publish skipped)." -ForegroundColor Green
    } else {
        Write-Host "Successfully built and published PPA Desktop version $Version." -ForegroundColor Green
    }
}
catch {
    Write-Error $_
    exit 1
}


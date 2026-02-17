<#
    publish-installer.ps1

    Helper script to publish a new PPA Desktop Windows installer (and related
    documentation) to the public GitHub “distribution” repository, without
    syncing the rest of this developer repo.

    What it does
    ------------
    - Looks in the local `windows\` folder for installer files for the
      specified version (both `.exe` and `.zip` are supported).
    - Collects the installer, the root `version.txt`, and key documentation
      files.
    - Uses the GitHub CLI (`gh`) to create or reuse a release in the
      distribution repository.
    - Uploads the selected files as release assets, replacing any existing
      files with the same names.

    Requirements
    ------------
    - GitHub CLI installed: https://cli.github.com/
    - Run once: `gh auth login` with an account that has permission to
      create and update releases in the distribution repository.

    Example usage
    -------------
    From the repository root:

        pwsh .\windows\publish-installer.ps1 -Version 1.5.1

    To override the distribution repository:

        pwsh .\windows\publish-installer.ps1 -Version 1.5.1 `
            -DistributionRepo "your-org/your-distribution-repo"
#>

param(
    # Semantic version of the installer, e.g. "1.5.1"
    [Parameter(Mandatory = $true)]
    [string]$Version,

    # GitHub "distribution" repository to publish to (owner/repo).
    # By default this points to the public PPA Desktop repo that
    # the installer update mechanism already uses.
    [string]$DistributionRepo = "kncvtbplus/ppa-desktop",

    # Base name of the installer files; the script will look for
    # <InstallerBaseName>-<Version>.exe and .zip in the windows folder.
    [string]$InstallerBaseName = "ppa-desktop-setup"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitHubCliPath {
    # Prefer PATH
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

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

    $exe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($exe) {
        return (Resolve-Path -LiteralPath $exe -ErrorAction Stop).Path
    }

    return $null
}

function Resolve-RepoRoot {
    # Try to resolve the repository root based on the script location.
    # NOTE: Inside a function, $MyInvocation.MyCommand is the *function*, not the script.
    # Use $PSScriptRoot / $PSCommandPath to locate this file reliably.
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
    $repoRoot = (Get-Item -LiteralPath (Join-Path $scriptDir "..") -ErrorAction Stop).FullName

    if (-not $repoRoot) {
        throw "Could not resolve repository root from script location."
    }

    return $repoRoot
}

function Get-FilesToUpload {
    param(
        [string]$RepoRoot,
        [string]$InstallerBaseName,
        [string]$Version
    )

    $windowsDir = Join-Path $RepoRoot "windows"

    if (-not (Test-Path $windowsDir)) {
        throw "Windows directory not found at '$windowsDir'."
    }

    # Candidate installer files (only those that actually exist are used)
    $exePath = Join-Path $windowsDir ("{0}-{1}.exe" -f $InstallerBaseName, $Version)
    $zipPath = Join-Path $windowsDir ("{0}-{1}.zip" -f $InstallerBaseName, $Version)

    $installerFiles = @()

    if (Test-Path $exePath) {
        $installerFiles += (Resolve-Path $exePath).Path
    }

    if (Test-Path $zipPath) {
        $installerFiles += (Resolve-Path $zipPath).Path
    }

    if ($installerFiles.Count -eq 0) {
        throw "No installer file found for version '$Version' in '$windowsDir'. Expected '$InstallerBaseName-$Version.exe' and/or '$InstallerBaseName-$Version.zip'."
    }

    # Documentation files to publish – only include those that currently exist.
    # Keep the text and PDF guides for end users; skip internal notes/info and
    # the editable .docx to keep the public release page clean.
    $docFileNames = @(
        # Keep only the PDF guide as the public-facing document; the
        # plain-text variant is no longer published to keep releases minimal.
        "PPA Desktop Installation and Local Use Guide.pdf"
    )

    $docFiles = foreach ($name in $docFileNames) {
        $fullPath = Join-Path $windowsDir $name
        if (Test-Path $fullPath) {
            (Resolve-Path $fullPath).Path
        }
    }

    # Extra top-level files that should travel with the installer
    $extraFiles = @()

    $versionFile = Join-Path $RepoRoot "version.txt"
    if (Test-Path $versionFile) {
        $extraFiles += (Resolve-Path $versionFile).Path
    }

    return $installerFiles + $docFiles + $extraFiles
}

function Ensure-GitHubCliAvailable {
    $script:GhExe = Get-GitHubCliPath
    if (-not $script:GhExe) {
        throw @"
GitHub CLI ('gh') was not found on this system.

Please install it from: https://cli.github.com/
Then run:    gh auth login
with an account or token that can create and update releases in '$DistributionRepo'.
"@
    }

    # Verify auth early so release upload doesn't fail mid-flight
    & $script:GhExe auth status -h github.com *> $null
    if ($LASTEXITCODE -ne 0) {
        throw @"
GitHub CLI is installed but not authenticated for github.com.

Run:
  `"$script:GhExe`" auth login

Then re-run this script.
"@
    }
}

function Ensure-ReleaseExists {
    param(
        [string]$DistributionRepo,
        [string]$Tag,
        [string]$ReleaseName
    )

    Write-Host "Checking for existing release '$Tag' in '$DistributionRepo'..."

    & $script:GhExe release view $Tag -R $DistributionRepo *> $null
    $exists = ($LASTEXITCODE -eq 0)

    if ($exists) {
        Write-Host "Release '$Tag' already exists; will upload/replace assets."
        return
    }

    Write-Host "Release '$Tag' does not exist; creating it..."

    & $script:GhExe release create $Tag `
        --repo $DistributionRepo `
        --title $ReleaseName `
        --notes "Automated release for PPA Desktop version $Version."

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create release '$Tag' in '$DistributionRepo'."
    }
}

function Upload-Assets {
    param(
        [string]$DistributionRepo,
        [string]$Tag,
        [string[]]$Files
    )

    if (-not $Files -or $Files.Count -eq 0) {
        Write-Warning "No files to upload – nothing to do."
        return
    }

    Write-Host "Uploading files to release '$Tag' in '$DistributionRepo':"
    foreach ($file in $Files) {
        Write-Host "  - $file"
    }

    $args = @(
        "release", "upload", $Tag
    ) + $Files + @(
        "--clobber",
        "--repo", $DistributionRepo
    )

    & $script:GhExe @args

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upload one or more assets to release '$Tag'."
    }
}

try {
    $repoRoot = Resolve-RepoRoot
    Write-Host "Repository root: $repoRoot"

    Ensure-GitHubCliAvailable

    $filesToUpload = Get-FilesToUpload -RepoRoot $repoRoot -InstallerBaseName $InstallerBaseName -Version $Version

    Write-Host "Collected $($filesToUpload.Count) file(s) to upload."

    $tag = "v$Version"
    $releaseName = "PPA Desktop $Version"

    Ensure-ReleaseExists -DistributionRepo $DistributionRepo -Tag $tag -ReleaseName $releaseName

    Upload-Assets -DistributionRepo $DistributionRepo -Tag $tag -Files $filesToUpload

    Write-Host "Done. Release '$tag' in '$DistributionRepo' now has the latest installer and documentation assets."
}
catch {
    Write-Error $_
    exit 1
}


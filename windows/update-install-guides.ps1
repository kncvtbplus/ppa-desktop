param(
    [string]$WindowsDir = $(Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$ErrorActionPreference = 'Stop'

$docxName = "PPA Desktop Installation and Local Use Guide.docx"
$pdfName  = "PPA Desktop Installation and Local Use Guide.pdf"

$docxPath = Join-Path $WindowsDir $docxName
$pdfPath  = Join-Path $WindowsDir $pdfName

if (-not (Test-Path -LiteralPath $docxPath)) {
    Write-Error "Could not find Word guide at '$docxPath'."
    exit 1
}

Write-Host "Updating installation text in:" -ForegroundColor Cyan
Write-Host "  DOCX: $docxPath"
Write-Host "  PDF : $pdfPath"

$word = $null
$doc  = $null

try {
    try {
        $word = New-Object -ComObject Word.Application
    } catch {
        Write-Error "Could not start Microsoft Word via COM. Please ensure Microsoft Word is installed on this machine."
        exit 1
    }

    $word.Visible = $false

    $doc = $word.Documents.Open($docxPath)

    $replacements = @(
        @{
            Old = "A PowerShell window will open. The first time this can take a few minutes:"
            New = "A small ""Starting PPA Desktop"" window will appear instead of a PowerShell script window. It shows the current step and a progress bar. The first time this can take a few minutes:"
        },
        @{
            Old = "3. If the newest version is the same as your installed version, it shows a short message that PPA Desktop is up to date and continues starting."
            New = "3. If the newest version is the same as your installed version, it shows a short message in the startup window that PPA Desktop is up to date and continues starting."
        },
        @{
            Old = "Download and start the latest installer now? (Y/N)"
            New = "The startup window asks whether to download and start the latest installer."
        },
        @{
            Old = "1. At the question above, type Y and press Enter."
            New = "1. In the question dialog, choose Yes to download and start the latest installer, or No to continue with your current version."
        },
        @{
            Old = "2. The script downloads the latest installer to a temporary folder and starts it automatically. If not started automatically double click the installer file."
            New = "2. When you choose Yes, the startup window downloads the latest installer to a temporary folder and starts it automatically. If it does not start automatically, double-click the downloaded installer file."
        }
    )

    foreach ($item in $replacements) {
        Write-Host "Replacing text:" -ForegroundColor DarkCyan
        Write-Host "  OLD: $($item.Old)"
        Write-Host "  NEW: $($item.New)"

        $find = $doc.Content.Find
        $null = $find.Execute(
            $item.Old,          # FindText
            $false,             # MatchCase
            $false,             # MatchWholeWord
            $false,             # MatchWildcards
            $false,             # MatchSoundsLike
            $false,             # MatchAllWordForms
            $true,              # Forward
            1,                  # Wrap = wdFindContinue
            $false,             # Format
            $item.New,          # ReplaceWith
            2                   # Replace = wdReplaceAll
        )
    }

    $doc.Save()
    Write-Host "Saved updated DOCX." -ForegroundColor Green

    # Export to PDF (will overwrite existing file if present)
    $wdExportFormatPDF = 17
    Write-Host "Exporting updated guide to PDF..." -ForegroundColor Cyan
    $doc.ExportAsFixedFormat($pdfPath, $wdExportFormatPDF) | Out-Null
    Write-Host "Saved updated PDF at: $pdfPath" -ForegroundColor Green
}
finally {
    if ($doc -ne $null) {
        $doc.Close($false)
    }
    if ($word -ne $null) {
        $word.Quit()
    }
}

Write-Host "Finished updating Word and PDF guides." -ForegroundColor Green

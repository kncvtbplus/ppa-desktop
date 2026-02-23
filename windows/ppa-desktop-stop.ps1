$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Tell Windows this is its own application so the taskbar shows our icon
# instead of the generic powershell.exe icon.
try {
  Add-Type -MemberDefinition @'
[DllImport("shell32.dll", SetLastError = true)]
public static extern void SetCurrentProcessExplicitAppUserModelID(
    [MarshalAs(UnmanagedType.LPWStr)] string AppID);
'@ -Namespace "PPA" -Name "AppId"
  [PPA.AppId]::SetCurrentProcessExplicitAppUserModelID("KNCV.PPA.Desktop.Stop")
} catch { }

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# --- Build a small status form with the PPA icon -------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Stopping PPA Desktop"
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ClientSize = New-Object System.Drawing.Size(420, 130)
$form.ShowInTaskbar = $true

$iconPath = Join-Path $ScriptDir "ppa-logo.ico"
if (Test-Path $iconPath) {
  try { $form.Icon = New-Object System.Drawing.Icon($iconPath) } catch { }
}

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.AutoSize = $false
$statusLabel.Size = New-Object System.Drawing.Size(390, 50)
$statusLabel.Location = New-Object System.Drawing.Point(15, 15)
$statusLabel.Text = "Stopping PPA Desktop services..."
$form.Controls.Add($statusLabel)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "OK"
$closeButton.Size = New-Object System.Drawing.Size(90, 28)
$closeButton.Location = New-Object System.Drawing.Point(315, 85)
$closeButton.Enabled = $false
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)
$form.AcceptButton = $closeButton

# --- Helper functions -----------------------------------------------------

function Test-DockerInstalled {
  try { docker --version *>$null; return $true } catch { return $false }
}

function Get-RunningDockerContainers {
  try {
    $output = docker ps -q 2>$null
    if ([string]::IsNullOrWhiteSpace($output)) { return @() }
    return $output -split '\s+'
  } catch { return @() }
}

function Stop-DockerDesktop {
  $stoppedAny = $false
  foreach ($name in @("Docker Desktop", "com.docker.backend", "com.docker.proxy")) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
      foreach ($p in $procs) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; $stoppedAny = $true } catch { }
      }
    }
  }
  return $stoppedAny
}

# --- Main logic (runs once the form is shown) -----------------------------

$form.Add_Shown({
  [System.Windows.Forms.Application]::DoEvents()

  try {
    if (-not (Test-DockerInstalled)) {
      $statusLabel.Text = "Docker Desktop does not seem to be installed."
      $closeButton.Enabled = $true
      return
    }

    $ComposeDir = Join-Path $ProjectRoot "local-dev"
    if (-not (Test-Path (Join-Path $ComposeDir "docker-compose.yml"))) {
      $statusLabel.Text = "Could not find 'local-dev/docker-compose.yml'.`r`nPlease reinstall PPA Desktop."
      $closeButton.Enabled = $true
      return
    }

    $statusLabel.Text = "Stopping PPA Desktop containers..."
    [System.Windows.Forms.Application]::DoEvents()

    # docker-compose writes progress to stderr; run via cmd to keep
    # PowerShell's ErrorActionPreference from treating it as an error.
    Push-Location $ComposeDir
    try {
      $proc = Start-Process -FilePath "docker-compose" -ArgumentList "down" `
                -WindowStyle Hidden -Wait -PassThru `
                -RedirectStandardError ([System.IO.Path]::GetTempFileName())
    } finally {
      Pop-Location
    }

    $statusLabel.Text = "PPA Desktop has been stopped."
    [System.Windows.Forms.Application]::DoEvents()

    $remainingContainers = Get-RunningDockerContainers
    if ($remainingContainers.Count -eq 0) {
      $statusLabel.Text = "Stopping Docker Desktop..."
      [System.Windows.Forms.Application]::DoEvents()

      $dockerStopped = Stop-DockerDesktop

      if ($dockerStopped) {
        $statusLabel.Text = "PPA Desktop and Docker Desktop have been stopped."
      } else {
        $statusLabel.Text = "PPA Desktop has been stopped."
      }
    }

    # Refresh any open localhost:8080 tab so the browser shows the page is
    # no longer reachable, making it clear PPA Desktop has stopped.
    try { Start-Process "http://localhost:8080" | Out-Null } catch { }

    $closeButton.Enabled = $true

    # Auto-close after a few seconds
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 3000
    $timer.Add_Tick({
      param($sender, $e)
      try { $sender.Stop() } catch { }
      try { if ($form -and -not $form.IsDisposed) { $form.Close() } } catch { }
    })
    $timer.Start()

  } catch {
    $statusLabel.Text = "Error: $($_.Exception.Message)"
    $closeButton.Enabled = $true
  }
})

[System.Windows.Forms.Application]::Run($form)

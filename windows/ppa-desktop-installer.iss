; Inno Setup script to package PPA Desktop as a Windows installer
; Requires Inno Setup (https://jrsoftware.org/isinfo.php)

[Setup]
AppId={{F8A5F5C3-4E7E-4B0A-8F0C-9E6A1B9E1F01}
AppName=PPA Desktop
AppVersion=1.8.5
AppPublisher=KNCV TB Plus
DefaultDirName={commonpf}\PPA Desktop
DefaultGroupName=PPA Desktop
DisableDirPage=no
DisableProgramGroupPage=no
OutputDir=.
OutputBaseFilename=ppa-desktop-setup-1.8.5
Compression=lzma
SolidCompression=yes
ChangesAssociations=yes
UninstallDisplayIcon={app}\windows\ppa-logo.ico
; Custom PPA logo for installer executable and wizard
; Use absolute path from the script directory so the icon is always found.
; Make sure ppa-logo.ico is present in the windows folder before compiling.
SetupIconFile={#SourcePath}\ppa-logo.ico
; WizardSmallImageFile expects a BMP or PNG bitmap; using only the .ico for now
;WizardSmallImageFile=ppa-logo.ico

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Core application and Docker setup
Source: "..\application.jar"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Dockerfile"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\local-dev\docker-compose.yml"; DestDir: "{app}\local-dev"; Flags: ignoreversion
; Version file used by the Windows start script to check for updates
Source: "..\version.txt"; DestDir: "{app}"; Flags: ignoreversion
; R script used to generate PPA outputs (copied into a writable data directory on first run)
Source: "..\local-dev\s3\script\Auto.PPA.UI.R"; DestDir: "{app}\local-dev\s3\script"; Flags: ignoreversion
Source: "..\rserve\Dockerfile"; DestDir: "{app}\rserve"; Flags: ignoreversion
; PPA logo icon for Start Menu / desktop shortcuts
Source: "ppa-logo.ico"; DestDir: "{app}\windows"; Flags: ignoreversion
; Dedicated .ppaw file-type icon
Source: "ppaw-file.ico"; DestDir: "{app}\windows"; Flags: ignoreversion

; Database tools (no pre-loaded data dump; local installs start with an empty DB)
Source: "..\scripts\restore_local.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion

; Windows helper scripts
Source: "ppa-desktop-run.ps1"; DestDir: "{app}\windows"; Flags: ignoreversion
Source: "ppa-desktop-stop.ps1"; DestDir: "{app}\windows"; Flags: ignoreversion
; VBS launchers suppress the brief PowerShell console flash on startup
Source: "ppa-desktop-run.vbs"; DestDir: "{app}\windows"; Flags: ignoreversion
Source: "ppa-desktop-stop.vbs"; DestDir: "{app}\windows"; Flags: ignoreversion
; User guide (PDF document only; DOCX is kept locally for editing but not shipped)
Source: "PPA Desktop Installation and Local Use Guide.pdf"; DestDir: "{app}\windows"; Flags: ignoreversion

[Icons]
Name: "{group}\PPA Desktop (Start)"; Filename: "wscript.exe"; Parameters: """{app}\windows\ppa-desktop-run.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\windows\ppa-logo.ico"
Name: "{group}\PPA Desktop (Stop)"; Filename: "wscript.exe"; Parameters: """{app}\windows\ppa-desktop-stop.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\windows\ppa-logo.ico"
Name: "{commondesktop}\PPA Desktop"; Filename: "wscript.exe"; Parameters: """{app}\windows\ppa-desktop-run.vbs"""; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "{app}\windows\ppa-logo.ico"

[Registry]
; Associate .ppaw files with PPA Desktop
; This registers a custom ProgID and uses the PPA Desktop workspace icon.
Root: HKCR; Subkey: ".ppaw"; ValueType: string; ValueData: "PPADesktop.PPAW"; Flags: uninsdeletevalue
; Explicitly set the default icon on both the ProgID and the extension key
; so Windows Explorer reliably picks up the custom .ppaw icon.
Root: HKCR; Subkey: ".ppaw\DefaultIcon"; ValueType: string; ValueData: "{app}\windows\ppaw-file.ico,0"; Flags: uninsdeletekey
Root: HKCR; Subkey: "PPADesktop.PPAW"; ValueType: string; ValueData: "PPA Desktop Workspace (.ppaw)"; Flags: uninsdeletekey
Root: HKCR; Subkey: "PPADesktop.PPAW\DefaultIcon"; ValueType: string; ValueData: "{app}\windows\ppaw-file.ico,0"; Flags: uninsdeletekey
Root: HKCR; Subkey: "PPADesktop.PPAW\shell\open\command"; ValueType: string; ValueData: """wscript.exe"" ""{app}\windows\ppa-desktop-run.vbs"" ""%1"""; Flags: uninsdeletekey

; Legacy .ppa export/import files still produced by the backend
; Map them to the same ProgID so double-click also opens PPA Desktop.
Root: HKCR; Subkey: ".ppa"; ValueType: string; ValueData: "PPADesktop.PPAW"; Flags: uninsdeletevalue

[Run]
; Offer to start PPA Desktop immediately after installation (default checked)
Filename: "wscript.exe"; Parameters: """{app}\windows\ppa-desktop-run.vbs"""; WorkingDir: "{app}"; Description: "Start PPA Desktop now"; Flags: nowait postinstall skipifsilent

; Offer to open the PDF installation guide after installation (uses the default .pdf handler)
Filename: "{app}\windows\PPA Desktop Installation and Local Use Guide.pdf"; Description: "Open the PPA Desktop installation guide (PDF)"; Flags: nowait postinstall skipifsilent shellexec unchecked

[Code]
var
  DockerDownloadPage: TDownloadWizardPage;

function IsDockerInstalled(): Boolean;
var
  ResultCode: Integer;
begin
  Result := ShellExec('', 'docker', '--version', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure InitializeWizard;
begin
  { Create a dedicated download page for Docker Desktop so users clearly see progress }
  DockerDownloadPage :=
    CreateDownloadPage(
      'Downloading Docker Desktop',
      'Please wait while the Docker Desktop installer is downloaded. This may take a few minutes.',
      nil);
end;

function DownloadDockerInstaller(const Url, Dest: string): Boolean;
var
  BaseName: string;
begin
  BaseName := ExtractFileName(Dest);

  DockerDownloadPage.Clear;
  DockerDownloadPage.Add(Url, BaseName, '');
  DockerDownloadPage.Show;
  try
    try
      { This shows a full download page with progress bar and details }
      DockerDownloadPage.Download;
      Result := True;
    except
      SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbCriticalError, MB_OK, IDOK);
      Result := False;
    end;
  finally
    DockerDownloadPage.Hide;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  DockerUrl: string;
  DestPath: string;
  ResultCode: Integer;
begin
  Result := True;

  { Before starting actual installation, ensure Docker Desktop is present }
  if (CurPageID = wpReady) then
  begin
    if not IsDockerInstalled() then
    begin
      if MsgBox(
           'PPA Desktop needs Docker Desktop to run.'#13#10#13#10 +
           'We cannot find Docker Desktop on this computer.'#13#10#13#10 +
           'This installer can download and start the Docker Desktop setup for you now.'#13#10 +
           'After Docker Desktop is installed, please run the PPA Desktop installer again.'#13#10#13#10 +
           'Do you want to download and start the Docker Desktop setup now?',
           mbConfirmation, MB_YESNO) = IDYES then
      begin
        DockerUrl := 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe';
        DestPath := ExpandConstant('{tmp}\DockerDesktopInstaller.exe');

        if not DownloadDockerInstaller(DockerUrl, DestPath) then
        begin
          MsgBox(
            'We could not download the Docker Desktop setup file.'#13#10 +
            'Please go to docker.com, install Docker Desktop, and then run the PPA Desktop installer again.',
            mbError, MB_OK);
          Result := False;
          exit;
        end;

        if not Exec(DestPath, '', '', SW_SHOWNORMAL, ewNoWait, ResultCode) then
        begin
          MsgBox(
            'We could not start the Docker Desktop setup.'#13#10 +
            'Please install Docker Desktop yourself and then run the PPA Desktop installer again.',
            mbError, MB_OK);
          Result := False;
          exit;
        end;

        MsgBox(
          'The Docker Desktop setup has been started.'#13#10#13#10 +
          'Please follow the steps in that window to install Docker Desktop.'#13#10 +
          'If it asks you to restart your computer, do that first and then run the PPA Desktop installer again.',
          mbInformation, MB_OK);

        { Close this installer so the user can complete Docker installation first }
        Result := False;
        WizardForm.Close;
      end
      else
      begin
        { User chose not to install Docker -> abort installation and close }
        Result := False;
        WizardForm.Close;
      end;
    end;
  end;
end;




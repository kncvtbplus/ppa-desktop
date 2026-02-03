; Inno Setup script to package PPA Wizard as a Windows installer
; Requires Inno Setup (https://jrsoftware.org/isinfo.php)

[Setup]
AppId={{F8A5F5C3-4E7E-4B0A-8F0C-9E6A1B9E1F01}
AppName=PPA Wizard
AppVersion=1.1.0
AppPublisher=KNCV TB Plus
DefaultDirName={pf}\PPA Wizard
DefaultGroupName=PPA Wizard
DisableDirPage=no
DisableProgramGroupPage=no
OutputDir=.
OutputBaseFilename=ppa-wizard-setup-1.1.0
Compression=lzma
SolidCompression=yes
UninstallDisplayIcon={app}\windows\ppa-logo.ico
; Custom PPA logo for installer executable and wizard
; Use absolute path from the script directory so the icon is always found.
; Make sure ppa-logo.ico is present in the windows folder before compiling.
SetupIconFile={#SourcePath}\ppa-logo.ico
; WizardSmallImageFile expects a BMP or PNG bitmap; using only the .ico for now
;WizardSmallImageFile=ppa-logo.ico
; Reserve extra disk space in the Windows installer UI to account for Docker
; Desktop (~3 GB) in addition to PPA Wizard itself (~300 MB).
; This makes the standard "At least ... MB of free disk space is required."
; text reflect the combined requirement.
ExtraDiskSpaceRequired=3000000000

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Core application and Docker setup
Source: "..\application.jar"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Dockerfile"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\local-dev\docker-compose.yml"; DestDir: "{app}\local-dev"; Flags: ignoreversion
; R script used to generate PPA outputs (copied into a writable data directory on first run)
Source: "..\local-dev\s3\script\Auto.PPA.UI.R"; DestDir: "{app}\local-dev\s3\script"; Flags: ignoreversion
Source: "..\rserve\Dockerfile"; DestDir: "{app}\rserve"; Flags: ignoreversion
; PPA logo icon for Start Menu / desktop shortcuts
Source: "ppa-logo.ico"; DestDir: "{app}\windows"; Flags: ignoreversion

; Database tools (no pre-loaded data dump; local installs start with an empty DB)
Source: "..\scripts\restore_local.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion

; Windows helper scripts
Source: "ppa-wizard-run.ps1"; DestDir: "{app}\windows"; Flags: ignoreversion
Source: "ppa-wizard-stop.ps1"; DestDir: "{app}\windows"; Flags: ignoreversion
; User guide
Source: "ppa-wizard-user-guide.txt"; DestDir: "{app}\windows"; Flags: ignoreversion

[Icons]
Name: "{group}\PPA Wizard (Start)"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\windows\ppa-wizard-run.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\windows\ppa-logo.ico"
Name: "{group}\PPA Wizard (Stop)"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\windows\ppa-wizard-stop.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\windows\ppa-logo.ico"
Name: "{commondesktop}\PPA Wizard"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\windows\ppa-wizard-run.ps1"""; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "{app}\windows\ppa-logo.ico"

[Run]
; Offer to open the simple user guide after installation
Filename: "notepad.exe"; Parameters: """{app}\windows\ppa-wizard-user-guide.txt"""; Description: "Open the quick PPA Wizard user guide in Notepad"; Flags: nowait postinstall skipifsilent

[Code]
function IsDockerInstalled(): Boolean;
var
  ResultCode: Integer;
begin
  Result := ShellExec('', 'docker', '--version', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function DownloadDockerInstaller(const Url, Dest: string): Boolean;
var
  ResultCode: Integer;
  Cmd: string;
begin
  { Use PowerShell to download the Docker Desktop installer }
  Cmd := '-ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing -Uri ''' + Url + ''' -OutFile ''' + Dest + '''"';
  Result := Exec('powershell.exe', Cmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  DockerUrl: string;
  DockerPageUrl: string;
  DestPath: string;
  ResultCode: Integer;
begin
  Result := True;

  { Before starting actual installation, ensure Docker Desktop is present }
  if (CurPageID = wpReady) then
  begin
    if not IsDockerInstalled() then
    begin
      if MsgBox('PPA Wizard needs Docker Desktop to run.'#13#10#13#10 +
                'Docker Desktop is not detected on this computer.'#13#10 +
                'Do you want to open the Docker Desktop download page now?', 
                mbConfirmation, MB_YESNO) = IDYES then
      begin
        DockerUrl := 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe';
        DockerPageUrl := 'https://www.docker.com/products/docker-desktop';

        { Open the Docker Desktop download URL in the default browser }
        if not ShellExec('', DockerUrl, '', '', SW_SHOWNORMAL, ewNoWait, ResultCode) then
        begin
          MsgBox('Could not open the Docker Desktop download page.'#13#10 +
                 'Please visit docker.com and install Docker Desktop manually, then run this PPA Wizard setup again.', 
                 mbError, MB_OK);
          Result := False;
          exit;
        end;

        { Also open the main Docker Desktop product page so the user sees context }
        ShellExec('', DockerPageUrl, '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);

        MsgBox('Your web browser has been opened on the Docker Desktop download page.'#13#10#13#10 +
               'Please download and install Docker Desktop.'#13#10 +
               'After the installation finishes (and Docker Desktop has started at least once), '#13#10 +
               'run this PPA Wizard installer again.', 
               mbInformation, MB_OK);

        { Cancel this installation so the user can complete Docker installation first }
        Result := False;
      end
      else
      begin
        { User chose not to install Docker -> abort installation }
        Result := False;
      end;
    end;
  end;
end;




; Inno Setup script to package PPA Wizard as a Windows installer
; Requires Inno Setup (https://jrsoftware.org/isinfo.php)

[Setup]
AppId={{F8A5F5C3-4E7E-4B0A-8F0C-9E6A1B9E1F01}
AppName=PPA Wizard
AppVersion=1.0.0
AppPublisher=KNCV Tuberculosis Foundation
DefaultDirName={pf}\PPA Wizard
DefaultGroupName=PPA Wizard
DisableDirPage=no
DisableProgramGroupPage=no
OutputDir=.
OutputBaseFilename=ppa-wizard-setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Core application and Docker setup
Source: "..\application.jar"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Dockerfile"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\local-dev\docker-compose.yml"; DestDir: "{app}\local-dev"; Flags: ignoreversion
Source: "..\rserve\Dockerfile"; DestDir: "{app}\rserve"; Flags: ignoreversion

; Database seed and tools
Source: "..\ppa-20251113153524.dump"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\scripts\restore_local.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion

; Windows helper scripts
Source: "ppa-wizard-run.ps1"; DestDir: "{app}\windows"; Flags: ignoreversion
Source: "ppa-wizard-stop.ps1"; DestDir: "{app}\windows"; Flags: ignoreversion

[Icons]
Name: "{group}\PPA Wizard (Start)"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\windows\ppa-wizard-run.ps1"""; WorkingDir: "{app}"; IconFilename: "powershell.exe"
Name: "{group}\PPA Wizard (Stop)"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\windows\ppa-wizard-stop.ps1"""; WorkingDir: "{app}"; IconFilename: "powershell.exe"
Name: "{commondesktop}\PPA Wizard"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\windows\ppa-wizard-run.ps1"""; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "powershell.exe"

[Run]
; Optionally open a README after installation
; Filename: "notepad.exe"; Parameters: """{app}\README-windows.txt"""; Flags: nowait postinstall skipifsilent

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
  DestPath: string;
  ResultCode: Integer;
begin
  Result := True;

  { Before starting actual installation, ensure Docker Desktop is present }
  if (CurPageID = wpReady) then
  begin
    if not IsDockerInstalled() then
    begin
      if MsgBox('Docker Desktop for Windows is required to run PPA Wizard.'#13#10#13#10 +
                'Docker does not appear to be installed on this system.'#13#10 +
                'Do you want to download and start the Docker Desktop installer now?', 
                mbConfirmation, MB_YESNO) = IDYES then
      begin
        DockerUrl := 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe';
        DestPath := ExpandConstant('{tmp}\DockerDesktopInstaller.exe');

        if not DownloadDockerInstaller(DockerUrl, DestPath) then
        begin
          MsgBox('Failed to download Docker Desktop installer. Please install Docker Desktop manually and then rerun this PPA Wizard setup.', 
                 mbError, MB_OK);
          Result := False;
          exit;
        end;

        if not ShellExec('', DestPath, '', '', SW_SHOWNORMAL, ewNoWait, ResultCode) then
        begin
          MsgBox('Could not start the Docker Desktop installer. Please run it manually from:'#13#10 + DestPath, 
                 mbError, MB_OK);
          Result := False;
          exit;
        end;

        MsgBox('The Docker Desktop installer has been started.'#13#10#13#10 +
               'After Docker installation completes (and Docker Desktop has started at least once), '#13#10 +
               'please rerun this PPA Wizard installer.', 
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




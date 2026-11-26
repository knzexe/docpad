#define AppName "Raifa Medicine & SS Health Care"
#ifndef AppVersion
#define AppVersion "1.0.0"
#endif
#define AppPublisher "Raifa Medicine & SS Health Care"
#define AppExeName "docpad.exe"

[Setup]
AppId={{0da77509-70b5-47d4-bfb7-d4543f2ec2fe}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
SignTool=DocPadSignTool
SignedUninstaller=yes
DefaultDirName={localappdata}\Programs\RaifaMedicine
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile={#SourcePath}\..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
OutputDir={#SourcePath}\..\..\build\windows\installer
OutputBaseFilename=RaifaMedicineSetup-{#AppVersion}-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "{#SourcePath}\..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; WorkingDir: "{app}"; Flags: postinstall nowait skipifsilent

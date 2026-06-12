; Inno Setup Script for Universal Share
; Make sure you have downloaded and installed Inno Setup (https://jrsoftware.org/isdl.php)

[Setup]
AppName=Universal Share
AppVersion=1.0.0
AppPublisher=Priyansh Verma
DefaultDirName={autopf}\Universal Share
DefaultGroupName=Universal Share
UninstallDisplayIcon={app}\universal_share.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.\build
OutputBaseFilename=UniversalShareSetup
SetupIconFile=.\windows\runner\resources\app_icon.ico
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: ".\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Avoid copying user settings databases or log files if they are in the build directory

[Icons]
Name: "{group}\Universal Share"; Filename: "{app}\universal_share.exe"
Name: "{commondesktop}\Universal Share"; Filename: "{app}\universal_share.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\universal_share.exe"; Description: "{cm:LaunchProgram,Universal Share}"; Flags: nowait postinstall skipifsilent

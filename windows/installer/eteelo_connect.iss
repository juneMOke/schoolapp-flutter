; eteelo_connect.iss — installateur Windows (Inno Setup 6).
;
; Compilé par la CI (.github/workflows/build_desktop.yml) APRÈS
; `flutter build windows --release` :
;
;   iscc /DAppVersion=1.2.3 /DAppEnv=prod windows\installer\eteelo_connect.iss
;
; Sortie : build\dist\eteelo-connect-<version>-<env>-windows-x64-setup.exe
;
; Une installation par environnement, comme les flavors Android : identifiant,
; nom et dossier distincts. Les bases locales sont de toute façon rangées par
; environnement (%APPDATA%\com.junethink\ETEELO CONNECT\databases\<env>), et
; la désinstallation ne les supprime JAMAIS — des versements peuvent y attendre
; leur envoi.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef AppEnv
  #define AppEnv "prod"
#endif

#if AppEnv == "prod"
  #define AppId "2ff63ecd-29c9-49fd-9ebe-d3cc6dbd933f"
  #define AppName "ETEELO CONNECT"
#elif AppEnv == "staging"
  #define AppId "4758dfd1-af6c-4412-82d7-993f292ebc7c"
  #define AppName "ETEELO CONNECT Staging"
#elif AppEnv == "dev"
  #define AppId "57c49c2d-e4e4-44bb-96cb-66eaf7985ca6"
  #define AppName "ETEELO CONNECT Dev"
#else
  #error AppEnv inconnu : attendu dev, staging ou prod.
#endif

#define AppExe "school_app_flutter.exe"
#define BundleDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{{#AppId}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=ETEELO
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Sans droits administrateur par défaut (installation pour l'utilisateur),
; l'installation pour tous reste proposée.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\build\dist
OutputBaseFilename=eteelo-connect-{#AppVersion}-{#AppEnv}-windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

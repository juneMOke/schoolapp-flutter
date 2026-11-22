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
; L'installation ferme l'application ouverte (Restart Manager)…
CloseApplications=yes
; … mais ne la relance pas elle-même : la mise à jour automatique la relance
; par l'entrée [Run] « IsUpdate » ci-dessous, une seule fois.
RestartApplications=no

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

; Avant la copie : aucun fichier d'une version précédente ne doit rester dans
; le programme (assets Flutter, `app.so`, bibliothèques natives renommées ou
; retirées). Les données de l'utilisateur ne sont PAS ici : elles vivent dans
; %APPDATA% et ne sont jamais touchées.
[InstallDelete]
Type: filesandordirs; Name: "{app}\data"
Type: files; Name: "{app}\*.dll"

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
; Mise à jour automatique : l'application lance l'installateur en silence avec
; `/UPDATE` (paramètre propre, que Setup ignore et que seul IsUpdate lit), puis
; se ferme. L'entrée ci-dessus est sautée en silence (`skipifsilent`) ; celle-ci
; relance l'application, avec les droits de l'utilisateur qui l'avait lancée.
Filename: "{app}\{#AppExe}"; Flags: nowait runasoriginaluser; Check: IsUpdate

[Code]
// Vrai si Setup a été lancé avec le paramètre `/UPDATE` (casse indifférente).
function IsUpdate: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if CompareText(ParamStr(I), '/UPDATE') = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

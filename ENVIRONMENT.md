# Configuration d’environnement

Ce projet utilise une approche hybride :

- `flavor` pour le contexte d’exécution (`dev`, `staging`, `prod`)
- `--dart-define` pour injecter les valeurs au build/run
- `EnvConfig` comme source de vérité côté application

## Variables reconnues

- `APP_ENV` : `dev`, `staging`, `prod` (obligatoire)
- `API_BASE_URL` : URL complète de l’API (obligatoire)
- `SHOW_ENVIRONMENT_BANNER` : `true` / `false`
- `ENABLE_VERBOSE_NETWORK_LOGGING` : `true` / `false`

## Matrice des environnements

| Environnement | Flavor    | Bundle / App ID attendu                  | Nom affiché          |
|---------------|-----------|------------------------------------------|----------------------|
| Dev           | `dev`     | `com.junethink.schoolAppFlutter.dev`     | `School App Dev`     |
| Staging       | `staging` | `com.junethink.schoolAppFlutter.staging` | `School App Staging` |
| Prod          | `prod`    | `com.junethink.schoolAppFlutter`         | `School App`         |

## Run local (Flutter)

### Dev

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

### Staging

```bash
flutter run --flavor staging --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.api.example.com
```

### Prod

```bash
flutter run --flavor prod --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

## Build Android

`dev` est le seul environnement construit en `--debug`. **`staging` se construit
exactement comme `prod`** — même `--release`, mêmes optimisations R8 /
`shrinkResources`, même keystore d'upload — seule l'URL de l'API diffère.

```bash
flutter build apk --flavor dev --debug --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build appbundle --flavor staging --release --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.api.example.com
flutter build appbundle --flavor prod --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

Un build `staging` **ou** `prod` en `--release` sans identifiants de signature
échoue désormais dans `build.gradle.kts` (`signedReleaseFlavors`) au lieu de
retomber silencieusement sur la clé debug : cette clé étant regénérée à chaque
machine / runner, une tablette de recette ne pourrait plus recevoir la mise à
jour suivante sans désinstallation.

### Build staging via GitHub Actions

Workflow `Build Android` → `environment: staging`.

- Secret requis : `STAGING_API_BASE_URL` (HTTPS obligatoire, loopback refusé par
  `validate_env.sh`), dans l'environnement GitHub `staging` ou au niveau dépôt.
- Signature : réutilise les secrets `ANDROID_RELEASE_KEYSTORE_BASE64` /
  `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD` de
  la prod. L'`applicationId` diffère (`.staging`), donc aucun conflit
  d'installation avec la prod sur la même tablette.
- Versionnement : `version` du `pubspec.yaml` + `GITHUB_RUN_NUMBER` comme
  `build_number`. **Aucun `version_tag` n'est requis** — il ne l'est que pour la
  prod.
- Distribution Firebase : `FIREBASE_APP_ID` doit être celui de l'app
  `com.junethink.schoolAppFlutter.staging`, défini dans l'environnement GitHub
  `staging` (l'App ID prod serait rejeté pour cause de package name différent).

## Signature Android release (option B recommandee)

Le projet utilise une signature release Android via secrets GitHub Actions
pour tout build produisant le buildType `release` : `prod` et `staging` (APK
comme App Bundle), ainsi que les App Bundles `dev`.

### Secrets GitHub requis

- `ANDROID_RELEASE_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

### Correspondance CI vers local

- CI: `ANDROID_RELEASE_KEYSTORE_BASE64` -> keystore reconstruit temporairement dans le runner
- Local: keystore present sur disque (pas besoin de base64)
- CI et local partagent la meme identite cryptographique (meme keystore, meme alias, meme mots de passe)

### Commandes utiles pour preparer les secrets

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
base64 -w 0 upload-keystore.jks > upload-keystore.base64
```

### Usage local (hors CI)

Créer `android/key.properties` (fichier ignore par git) :

```properties
storeFile=/chemin/absolu/vers/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

### Build release local signe (Android)

```bash
flutter build apk --flavor prod --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --flavor prod --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

### Alternative locale sans `key.properties`

Le `build.gradle.kts` supporte aussi un fallback via variables d'environnement shell :

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Exemple :

```bash
export ANDROID_KEYSTORE_PATH=/home/you/.android/upload-keystore.jks
export ANDROID_KEYSTORE_PASSWORD='...'
export ANDROID_KEY_ALIAS='upload'
export ANDROID_KEY_PASSWORD='...'

flutter build appbundle --flavor prod --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

## Build iOS

Les schemes partagés attendus sont `dev`, `staging`, `prod`.

```bash
flutter build ios --flavor dev --debug --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build ios --flavor staging --release --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.api.example.com
flutter build ipa --flavor prod --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

## Checklist release iOS

- Vérifier que le flavor est bien `prod`
- Vérifier `APP_ENV=prod`
- Vérifier `API_BASE_URL` de production
- Vérifier le bundle id `com.junethink.schoolAppFlutter`
- Vérifier le profil de signature/certificat de prod dans Xcode
- Vérifier l’écran de QA indiquant l’environnement attendu (si bannière activée)

## Garde-fous

- Ne pas hardcoder d’URL API dans le code applicatif
- Faire échouer le pipeline si `APP_ENV` ou `API_BASE_URL` est manquant
- Garder les variables injectées centralisées via `EnvConfig`
- Garder ce document aligné avec `android/app/build.gradle.kts` et `ios/Runner.xcodeproj/project.pbxproj`

## Formatage Dart (B4)

Le CI valide le formatage Dart avec :

```bash
dart format --output=none --set-exit-if-changed .
```

Pour le confort local, un hook `pre-commit` est versionné dans `.githooks/pre-commit`.

Installation locale du hook :

```bash
bash scripts/install_git_hooks.sh
```

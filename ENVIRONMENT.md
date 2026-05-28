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

```bash
flutter build apk --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build appbundle --flavor staging --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.api.example.com
flutter build appbundle --flavor prod --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

## Signature Android release (option B recommandee)

Le projet utilise une signature release Android via secrets GitHub Actions pour les builds `prod` (et les builds `appbundle`).

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

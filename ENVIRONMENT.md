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

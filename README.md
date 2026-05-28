# school_app_flutter

Application Flutter de gestion scolaire, organisée en Clean Architecture (features, BLoC, GetIt, Dio/Retrofit,
Hive/SecureStorage).

## Démarrage rapide

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
bash scripts/install_git_hooks.sh
```

## Lancer l'application localement

Les environnements utilisent des flavors (`dev`, `staging`, `prod`) + `--dart-define`.

### Dev

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

### Staging

```bash
flutter run --flavor staging --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.api.example.com
```

### Prod (test local)

```bash
flutter run --flavor prod --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

Pour le détail environnement/signing/build: voir `ENVIRONMENT.md`.

## Commandes essentielles

```bash
# Analyse statique
flutter analyze

# Tests
flutter test

# Génération Retrofit / JSON
flutter pub run build_runner build --delete-conflicting-outputs

# Génération des localisations
flutter gen-l10n

# Vérification format (comme en CI)
dart format --output=none --set-exit-if-changed .
```

## Hooks Git locaux

| Hook         | Déclencheur  | Vérification                                 |
|--------------|--------------|----------------------------------------------|
| `pre-commit` | `git commit` | format Dart auto-stagé + motion tokens check |
| `pre-push`   | `git push`   | `flutter analyze` + `flutter test`           |

Installation (une seule fois):

```bash
bash scripts/install_git_hooks.sh
```

Bypass d'urgence: `git commit --no-verify` / `git push --no-verify`.

## Release production

Consulter en priorité:

- `GITHUB_RELEASE_STEP_BY_STEP.md` (guide complet clic par clic)
- `GITHUB_RELEASE_RUNBOOK.md` (mode opératoire interne)
- `GITHUB_RELEASE_CHECKLIST.md` (checklist 1 page)

## Architecture et conventions

Point d'entrée recommandé pour comprendre le projet:

- `AGENTS.md` (architecture, patterns, flux de données)
- `CLAUDE.md` (règles opérationnelles et workflow)
- `INDEX.md` (index des guides/templates)
- `PROD_READINESS.md` (suivi des risques avant prod)

## Dépannage rapide

- Si `build_runner` échoue: `flutter clean` puis relancer la commande de génération.
- Si les strings ne se mettent pas à jour: relancer `flutter gen-l10n`.
- Si une URL staging/prod est en `http://`: le pipeline peut échouer volontairement via `scripts/validate_env.sh`.

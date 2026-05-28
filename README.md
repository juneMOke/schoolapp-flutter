# school_app_flutter

A school management App

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Setup après clone

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Activer les hooks Git locaux (à faire une seule fois)
bash scripts/install_git_hooks.sh
```

## Hooks Git locaux

| Hook | Déclencheur | Ce qu'il fait |
|---|---|---|
| `pre-commit` | `git commit` | Format Dart auto + motion tokens check |
| `pre-push` | `git push` | `flutter analyze` + `flutter test` |

Bypass : `git commit --no-verify` / `git push --no-verify`

## Commandes utiles

Forcer la regénération des fichiers de localisation :

```bash
flutter gen-l10n
```

Forcer la regénération des fichiers Retrofit / JSON :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

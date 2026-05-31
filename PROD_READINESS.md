# PROD_READINESS.md — school_app_flutter

Diagnostic de l'état du projet avant mise en production.
Document vivant — à mettre à jour à mesure que les points sont traités.

> **Échelle de criticité**
> - **A** — Bloquant prod. À corriger avant tout déploiement.
> - **B** — Fortement recommandé avant prod. Risque réel mais pas immédiatement bloquant.
> - **C** — Souhaitable. Peut être traité en parallèle du lancement.
> - **D** — Nice-to-have / amélioration continue.

---

## ✅ Ce qui est bien fait

| #  | Élément                               | Détail                                                                                                                                                                                                             |
|----|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | **Architecture Clean** rigoureuse     | 3 couches (data/domain/presentation) appliquées sur **tous** les modules. Séparation entité/modèle, repository abstrait/impl, usecase par opération.                                                               |
| 2  | **Documentation IA exemplaire**       | `AGENTS.md`, `copilot-instructions.md`, `CLAUDE.md`, `FEATURE_TEMPLATE.md`, `QUICK_TEMPLATE.md`, `USAGE_GUIDE.md`, `INDEX.md`. Onboarding agent et humain de premier ordre.                                        |
| 3  | **`flutter analyze` clean**           | Zéro warning sur ~60k lignes. Lints strictes : `avoid_print`, `prefer_const_constructors`, `prefer_single_quotes`, `always_use_package_imports`.                                                                   |
| 4  | **Either pattern systématique**       | `Future<Either<Failure, T>>` partout, `.fold()` appliqué. Pas d'exception leak vers la couche présentation.                                                                                                        |
| 5  | **DI bien typée**                     | Ordre `Dio → DataSource → Repo → UseCase → BLoC` respecté. BLoCs en factory (pas de fuite d'état entre écrans).                                                                                                    |
| 6  | **Stockage de tokens sécurisé**       | `FlutterSecureStorage` via `TokenStorageService`, jamais en clair dans Hive/SharedPreferences.                                                                                                                     |
| 7  | **Migrations Hive** prévues           | `BootstrapLocalMigrationService` + `bootstrapSchemaVersionKey`.                                                                                                                                                    |
| 8  | **Localisation FR + EN complète**     | `app_fr.arb` + `app_en.arb` + génération automatique. Pas de strings en dur.                                                                                                                                       |
| 9  | **Couverture de tests solide**        | ~8 300 lignes de tests pour ~60k lignes de code, sur les zones critiques (`auth_bloc`, `enrollment_bloc`, `attendance_bloc`, `finance_repository`, widgets clés).                                                  |
| 10 | **CI complète en place**              | `flutter_ci.yml` : validate env + dart format + analyze + build_runner + gen-l10n + motion tokens check + tests + coverage. `build_android.yml` + `build_ios.yml` + `release_prod.yml` pour les builds par flavor. |
| 11 | **Hooks locaux Git actifs**           | `.githooks/pre-commit` (format Dart auto + motion tokens) · `.githooks/pre-push` (flutter analyze + flutter test) · activation : `bash scripts/install_git_hooks.sh`.                                              |
| 12 | **Pas de `print()` ni `debugPrint`**  | Code propre côté logs.                                                                                                                                                                                             |
| 13 | **Aucun secret committed**            | Pas de `.env`, pas de clés API en dur.                                                                                                                                                                             |
| 14 | **Couplage Auth↔Bootstrap explicite** | Listener unique dans `main.dart`, sens unique.                                                                                                                                                                     |
| 15 | **TODOs résiduels quasi-nuls**        | Un seul TODO dans `top_bar_profile_menu_button.dart`.                                                                                                                                                              |
| 16 | **Flavors Android + iOS configurés**  | `dev` / `staging` / `prod` dans `build.gradle.kts` et `project.pbxproj`. Schemes iOS partagés. Xcconfig par flavor.                                                                                                |
| 17 | **EnvConfig + validation HTTPS**      | `EnvConfig.fromDartDefines()` lit `APP_ENV` + `API_BASE_URL`. Impose `https://` pour staging/prod. `scripts/validate_env.sh` bloque le CI si URL incohérente ou http en non-dev.                                   |
| 18 | **Couverture env testée**             | `test/core/config/env_config_test.dart` — cas http/https par env couverts.                                                                                                                                         |

---

## 🚨 Ce qui doit être amélioré

### 🔴 Criticité A — Bloquant prod

| #  | Élément                                               | Constat                                                                                                                                                | Action                                                                                                                                | Statut                                                                                                                                                                                                                                  |
|----|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A1 | **URL d'API hardcodée en dev**                        | `AppConstants.baseUrl = 'http://10.0.2.2:8080'` — loopback de l'émulateur Android vers `localhost`. Aucun build prod ne peut fonctionner avec ça.      | Introduire un système de flavors / `--dart-define=API_BASE_URL=...` ou un `EnvConfig` par environnement (dev/staging/prod).           | ☑ `EnvConfig` + flavors + `--dart-define=API_BASE_URL`. Secrets via GitHub Actions.                                                                                                                                                     |
| A2 | **HTTP en clair (pas de TLS)**                        | `http://` au lieu de `https://`. Tokens et données élèves transitent en clair.                                                                         | Imposer `https://` sur staging/prod. Sans cleartext exception : pas d'`android:usesCleartextTraffic="true"`, pas d'ATS exception iOS. | ☑ `EnvConfig` + `validate_env.sh` refusent `http` pour staging/prod. Pas de `usesCleartextTraffic` dans le manifest. ⚠️ Vérifier que le backend est bien servi en HTTPS.                                                                |
| A3 | **Release Android signée avec la clé debug**          | `android/app/build.gradle.kts:37` : `signingConfig = signingConfigs.getByName("debug")`. Un APK signé debug ne peut pas être publié sur le Play Store. | Créer un `key.properties` (non versionné), un `signingConfigs.release {…}`, et passer le release dessus.                              | ☑ `signingConfigs.release` créé (lines 31-45), charge depuis `key.properties` ou env vars (`ANDROID_KEYSTORE_*`). `buildTypes.release` assignée correctement (line 96).                                                                 |
| A4 | **`INTERNET` non déclaré dans `AndroidManifest.xml`** | Flutter l'injecte automatiquement en debug, **pas en release**. L'APK release n'aura pas accès réseau.                                                 | Ajouter `<uses-permission android:name="android.permission.INTERNET"/>` explicitement.                                                | ☑ Permission ajoutée dans `AndroidManifest.xml`.                                                                                                                                                                                        |
| A5 | **`versionCode` / `versionName` non gérés**           | Reposent sur `pubspec.yaml` bloqué à `1.0.0+1`. Aucune stratégie de bump.                                                                              | Définir une convention de versioning (semver + bump auto via CI ou tag git).                                                          | ☑ Version prod pilotée par un tag SemVer (`vX.Y.Z`) via `scripts/resolve_flutter_version.sh` ; `build-name`/`build-number` injectés dans les workflows Android/iOS. Dev/staging utilisent la base `pubspec.yaml` + `GITHUB_RUN_NUMBER`. |

### 🟠 Criticité B — Fortement recommandé

| #  | Élément                                                      | Constat                                                                                                                                                         | Action                                                                                                                    | Statut                                                                                                                                                 |
|----|--------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| B1 | **Aucun reporting de crash**                                 | Pas de Sentry / Crashlytics / Firebase. En prod, les crashs disparaissent dans le vide.                                                                         | Intégrer `sentry_flutter` ou `firebase_crashlytics` + setup `FlutterError.onError` et `PlatformDispatcher.onError`.       | ☐                                                                                                                                                      |
| B2 | **Aucune stratégie de logging**                              | Zéro `debugPrint` / `developer.log`. Bien en dev mais en cas d'incident utilisateur, rien n'est traçable.                                                       | Ajouter un `LoggerService` abstrait (no-op en prod si pas envoyé à Sentry, sinon breadcrumbs).                            | ☐                                                                                                                                                      |
| B3 | **CI ne build pas l'APK/IPA**                                | `flutter_ci.yml` ne fait ni `flutter build apk` ni `flutter build ios`. Une régression de build n'est détectée qu'au release.                                   | Ajouter un job `build` (au moins `flutter build apk --debug` pour ne pas requérir de signing key sur CI public).          | ☑ `build_android.yml` (APK + App Bundle, par flavor) et `build_ios.yml` (runner macOS) ajoutés. `release_prod.yml` pour la prod avec approbation.      |
| B4 | **CI ne vérifie pas le `dart format`**                       | Risque de drift de style entre devs.                                                                                                                            | Ajouter `dart format --output=none --set-exit-if-changed .`                                                               | ☑ Step `dart format --output=none --set-exit-if-changed .` dans `flutter_ci.yml`. Hook `pre-commit` formate aussi automatiquement les fichiers stagés. |
| B5 | **CI ne vérifie pas le `build_runner`**                      | Si un dev oublie de regen, les `.g.dart` désynchronisés peuvent passer.                                                                                         | Ajouter une étape : `dart run build_runner build --delete-conflicting-outputs` puis `git diff --exit-code`                | ☑ `flutter pub run build_runner build` ajouté dans `flutter_ci.yml` et tous les workflows de build.                                                    |
| B6 | **CI ne se déclenche que sur push `main`/`master`**          | Sur les branches feature, aucun push n'est analysé tant qu'il n'y a pas de PR.                                                                                  | Étendre le trigger : `on: push: branches: [main, master, 'feature/**']` ou retirer le filtre.                             | ☑ `flutter_ci.yml` déclenché sur `main`, `master`, `develop`, `feature/**`, `fix/**`.                                                                  |
| B7 | **Interceptor Dio ne gère pas le refresh token / retry 401** | Le token est ajouté mais pas refresh. Si expiration en pleine session → logout brutal.                                                                          | Implémenter un refresh ou au minimum un message utilisateur clair + redirection login propre.                             | ☐                                                                                                                                                      |
| B8 | **Pas de gestion offline**                                   | Hive utilisé pour bootstrap mais aucune politique offline-first sur les CRUD (enrollment, attendance, finance). Une coupure réseau côté école = écran d'erreur. | Définir explicitement ce qui doit fonctionner offline (présences typiquement) et cacher les écrans qui ne le peuvent pas. | ☐                                                                                                                                                      |

### 🟡 Criticité C — Souhaitable

| #  | Élément                             | Constat                                                                                               | Action                                                                                                               | Statut                                                                                                                                                                                                       |
|----|-------------------------------------|-------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| C1 | **`README.md` minimal**             | 28 lignes, template Flutter par défaut + 2 commandes. Pas de setup, pas de description fonctionnelle. | Écrire un vrai README : public cible, modules, setup local, comment lancer les tests, où trouver la doc IA.          | ☑ `README.md` restructuré en landing page (quick start, env/flavors, commandes clés, release, conventions, troubleshooting) + liens vers docs détaillées.                                                    |
| C2 | **Pas de ProGuard/R8 rules**        | Release Android non minifiée → APK plus gros, code plus facile à reverse.                             | Activer `isMinifyEnabled = true` + `isShrinkResources = true` + tester avec les rules par défaut Flutter.            | ☑ Activation sur `android/app/build.gradle.kts` (`isMinifyEnabled`, `isShrinkResources`, `proguardFiles`) + fichier `android/app/proguard-rules.pro` ajouté. Validation R8 via `app:minifyDevReleaseWithR8`. |
| C3 | **Couverture de tests non mesurée** | Pas de `--coverage` dans la CI, pas d'upload codecov.                                                 | Ajouter `flutter test --coverage` + `codecov-action`. Cible pragmatique : 70%+ sur domain/data.                      | ☑ `flutter test --coverage` + `codecov-action` dans `flutter_ci.yml`. `test/core/config/env_config_test.dart` ajouté.                                                                                        |
| C4 | **Pas de tests d'int��gration**     | Tests unitaires et widgets uniquement. Aucun `integration_test/`.                                     | Ajouter 2-3 tests d'intégration sur les golden paths (login → home, enrollment complet, paiement).                   | ☐                                                                                                                                                                                                            |
| C5 | **iOS `Info.plist` minimal**        | Aucune `NSAppTransportSecurity`, pas d'`UIBackgroundModes`, pas de `LSApplicationCategoryType`.       | Compléter selon les besoins (permissions caméra/photo si utilisé un jour).                                           | ☐                                                                                                                                                                                                            |
| C6 | **Aucune analytics produit**        | Pas de mesure d'usage. Difficile de prioriser les évolutions post-lancement.                          | Décider explicitement : analytics ou pas (RGPD côté école). Si oui : Firebase Analytics ou alternative respectueuse. | ☐                                                                                                                                                                                                            |
| C7 | **Dépendances pas auditées**        | Pas de `dependabot.yml` ni d'équivalent.                                                              | Ajouter un `.github/dependabot.yml` (weekly, pubspec).                                                               | ☐                                                                                                                                                                                                            |
| C8 | **Pas de pre-commit hooks**         | `scripts/check_motion_tokens.sh` ne tourne qu'en CI.                                                  | Optionnel : `lefthook` ou `husky` pour faire tourner format + analyze avant push.                                    | ☑ `.githooks/pre-commit` (format Dart auto-stagé + motion tokens) · `.githooks/pre-push` (analyze + tests) · activation : `bash scripts/install_git_hooks.sh`.                                               |

### 🟢 Criticité D — Nice-to-have

| #  | Élément                                                                                                          | Constat                                                                                   | Statut |
|----|------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|--------|
| D1 | **TODO résiduel** dans `lib/features/home/presentation/widget/top_bar_parts/top_bar_profile_menu_button.dart:25` | Soit l'implémenter, soit créer une issue et référencer son numéro.                        | ☐      |
| D2 | **Pas de PR template**                                                                                           | `.github/PULL_REQUEST_TEMPLATE.md` aiderait à standardiser.                               | ☐      |
| D3 | **Pas d'`ISSUE_TEMPLATE`**                                                                                       | Idem pour les bug reports.                                                                | ☐      |
| D4 | **`AppRouter` est statique**                                                                                     | `AppRouter.createRouter()` est OK mais une instance gérée par DI faciliterait le testing. | ☐      |
| D5 | **Splash screen iOS**                                                                                            | `flutter_native_splash` configuré pour Android, à vérifier sur iOS.                       | ☐      |
| D6 | **`FINANCE_MOTION_MAP.md` à la racine**                                                                          | Le déplacer dans `docs/` ou dans `lib/features/finance/` pour mieux cadrer où vit la doc. | ☐      |

---

## 🎯 Top 5 à traiter avant la prod

~~1. **A1 + A2** — flavors + HTTPS (les deux ensemble, une seule itération)~~  ☑ Traités
~~**A3** — signing release Android (clé debug encore utilisée → bloquant Play Store)~~ ☑ Traité
~~4. **A4** — permission INTERNET dans le manifest~~  ☑ Traité
~~**B4** — `dart format` dans la CI~~  ☑ Traité
~~**C8** — hooks locaux (format + motion tokens + analyze + tests)~~  ☑ Traité
~~**C1** — `README.md` minimal~~ ☑ Traité
~~**C2** — ProGuard/R8 rules sur Android release~~ ☑ Traité

1. **B1** — Crashlytics / Sentry, sinon prod = boîte noire
2. **B7** — comportement sur token expiré (UX + sécurité)
3. **B2** — LoggerService (traçabilité incidents en prod)
4. **B3** — CI build APK/IPA (regression détection)
5. **C4** — tests d'intégration sur les golden paths

Le reste est rattrapable post-lancement sans risque utilisateur immédiat.

---

## 📅 Méthode de suivi suggérée

- Cocher la case Statut (☐ → ☑) au fil des PR qui traitent chaque point.
- Créer une issue GitHub par item A et B avec le label `prod-readiness`.
- Re-générer le diagnostic (ou demander à l'agent de le faire) à chaque jalon : avant beta, avant release publique,
  après 1 mois en prod.

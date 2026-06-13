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

## À faire

### Splash (améliorations différées)

- [ ] **Wordmark en Inter ExtraBold (800)** — seuls les poids 400/500/600/700 d'Inter sont bundlés, donc « ETEELO » se rabat actuellement sur le poids 700. Ajouter `Inter-ExtraBold.ttf` dans `assets/fonts/inter/` + entrée `pubspec.yaml` pour le vrai 800.
- [ ] **Alternative « lockup horizontal » en paysage large** (spec splash, COMPOSANT 02) — afficher le logo horizontal complet (`assets/branding/fonce/logo_horizontal_fond_fonce.svg`) à la place du symbole + wordmark texte sur les écrans larges en paysage.

### États partagés (chargement / vide / erreur)

Suite à la migration de la Présence sur les widgets d'état partagés (règle non-négociable #10, cf. `AGENTS.md` §"États partagés"). Améliorations différées, non bloquantes :

- [ ] **Migrer le squelette d'`enrollment` vers le module partagé** — `EnrollmentResultsLoadingSkeleton` (≈244 lignes) duplique encore le pattern. Réutiliser `EteeloListSkeleton` pour le mode liste et créer un `EteeloGridSkeleton` (carte) pour le mode grille, puis brancher l'un ou l'autre selon `isGrid`. Aligne enrollment sur le module `core/components/skeletons/`.
- [ ] **Centraliser l'email de support** — adopter `AppConstants.supportEmail` dans les pages d'inscription qui dupliquent encore `support@school.local` (`first_registration_page.dart`, `re_registrations_page.dart`, `pre_registrations_page.dart`).
- [ ] **Renforcer l'a11y de `EteeloListSkeleton`** — rendre `semanticsLabel` requis (ou fournir un libellé i18n par défaut) pour éviter une région `aria-busy` muette si le widget est réutilisé sans libellé.

### Statistiques (période & mapping d'erreur partagés)

Suite à l'ajout du résumé de présence (`attendance-stats`), qui introduit le `StatsPeriod` partagé (`core/entities/stats_period.dart`) et le mapper d'erreur partagé (`attendance_failure_mapper.dart`). Factorisations différées, non bloquantes :

- [ ] **Migrer finance & enrollment vers `StatsPeriod`** — remplacer les enums dupliqués `FinanceStatsPeriod` et `EnrollmentStatsPeriod` (identiques à `StatsPeriod`) par `core/entities/stats_period.dart`, puis supprimer les deux fichiers. ~15 fichiers + tests à adapter.

### Discipline — dépendances backend (UI posée, à câbler)

Suite à la refonte de l'onglet Discipline (cartes de cas, frise de statut, modale enrichie). Éléments de la spec laissés **dormants / différés** faute de support backend :

- [ ] **Avancement de statut** — le bouton « Prendre en charge / Clôturer » est présent mais **inerte** (`onAdvance: (_) {}` dans `disciplinary_cases_tab`). Câbler quand un endpoint `PATCH /disciplinary-cases/{id}` (ou équivalent) existera + ajouter l'event/usecase/repo correspondants.
- [ ] **Journal / historique** des transitions — non implémenté (aucune donnée `history` côté backend).
- [ ] **Auteur / rapporteur** du cas — champ absent du DTO ; chip auteur non affiché.
- [ ] **Filtre période** — la liste se charge par `studentId + academicYearId` (pas de paramètre de période) ; le segmenté période de la spec n'est pas posé.
- [ ] **Modale création** : les champs catégorie/gravité/sanction sont envoyés via `CreateDisciplinaryCaseRequest` — **vérifier que le backend de création les accepte/stocke** (supposé OK).
- [ ] **Nettoyage** : `disciplinary_cases_table.dart` et `disciplinary_case_view_dialog.dart` (+ le flux `getDisciplinaryCaseDetail`) sont **orphelins** depuis le passage en cartes — à supprimer si confirmé inutiles.

## Dépannage rapide

- Si `build_runner` échoue: `flutter clean` puis relancer la commande de génération.
- Si les strings ne se mettent pas à jour: relancer `flutter gen-l10n`.
- Si une URL staging/prod est en `http://`: le pipeline peut échouer volontairement via `scripts/validate_env.sh`.

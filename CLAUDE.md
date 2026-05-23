# CLAUDE.md — school_app_flutter

Guide opérationnel pour Claude Code sur ce projet.
Pour les patterns détaillés (Retrofit, BLoC, FeatureScope…), lire **AGENTS.md**.

---

## Stack en une ligne

Flutter + Clean Architecture (3 couches) · flutter_bloc · GetIt · Dio + Retrofit ·
GoRouter · Hive + FlutterSecureStorage · dartz (`Either<Failure, T>`).

## Commandes essentielles

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # après tout @RestApi / @JsonSerializable
flutter gen-l10n                                                  # après modif app_fr.arb / app_en.arb
flutter analyze
flutter test
flutter run
```

Si `build_runner` casse : `flutter clean` puis relancer (cf. AGENTS.md §"When Build Runner Fails").

## Règles non-négociables (ne pas enfreindre sans demander)

1. **Either pattern partout** — toujours `.fold()`, jamais d'unwrap direct de `Left`/`Right`.
2. **BLoCs en `registerFactory`** dans `lib/core/di/injection.dart`. Jamais singleton.
3. **Models → Entities dans le repository** (via `.toEntity()`), jamais dans le BLoC.
4. **Zéro string UI hardcodée** → tout passe par `AppLocalizations` (`app_fr.arb` + `app_en.arb`).
5. **Zéro couleur/dimension/style hardcodés** → `AppColors`, `AppDimensions`, `AppTextStyles`.
6. **Zéro endpoint en dur** → `AppConstants`.
7. **Cible ~250 lignes max par fichier** — au-delà, décomposer en widgets/usecases.
8. **`mounted` guard après chaque `await`** dans un `StatefulWidget`.
9. **`buildWhen` / `listenWhen`** dès qu'un rebuild partiel est possible.

## Modules (`lib/features/`)

| Module | Rôle | Spécificités |
|---|---|---|
| `auth` | Login, OTP, reset password, JWT | flow complexe · voir `lib/features/auth/CLAUDE.md` |
| `bootstrap` | Chargement initial des données après auth | bloque la navigation · voir `lib/features/bootstrap/CLAUDE.md` |
| `splash` | Écran d'attente initial | pattern standard |
| `home` | Dashboard post-connexion | pattern standard |
| `student` | CRUD élèves | pattern standard |
| `classes` | Gestion des classes | pattern standard |
| `enrollment` | Inscriptions des élèves | utilise `FeatureScope` (cf. AGENTS.md §11) |
| `attendances` | Présences | pattern standard |
| `academic_year` | Années scolaires | pattern standard |
| `finance` | Paiements et frais scolaires | voir aussi `FINANCE_MOTION_MAP.md` |

## Fichiers où atterrir en premier

| Pour... | Aller voir |
|---|---|
| Patterns détaillés (BLoC, Retrofit, Model, FeatureScope) | `AGENTS.md` |
| Templates de nouvelle feature | `FEATURE_TEMPLATE.md`, `QUICK_TEMPLATE.md`, `USAGE_GUIDE.md` |
| Index général de la doc | `INDEX.md` |
| Registrations DI | `lib/core/di/injection.dart` |
| Routes & redirect logic | `lib/router/app_router.dart`, `lib/router/app_routes_names.dart` |
| Types de Failure | `lib/core/error/failures.dart` |
| Couplage Auth ↔ Bootstrap | `lib/main.dart` |
| Référence de test BLoC | `test/features/auth/presentation/bloc/auth_bloc_test.dart` |

## Fichiers générés (ne PAS éditer à la main)

- `lib/**/*.g.dart` (json_serializable, retrofit)
- `lib/l10n/app_localizations*.dart` (flutter gen-l10n)
- `lib/gen/`, `lib/generated/`
- `.dart_tool/`, `build/`

Pour modifier → éditer la source (`.dart` annoté, `.arb`) et relancer le générateur.

## Workflow "nouvelle feature" (résumé)

1. Créer `lib/features/{feature}/{data,domain,presentation}/…`
2. Domain → Data → Presentation (cf. `FEATURE_TEMPLATE.md`)
3. Enregistrer dans `injection.dart` (ordre : DataSource → Repository → UseCase → BLoC)
4. Route dans `app_router.dart` + constante dans `app_routes_names.dart`
5. Strings FR + EN dans `lib/l10n/`, puis `flutter gen-l10n`
6. `build_runner` si modèles/Retrofit
7. Tests miroir dans `test/features/{feature}/`

## Checklist avant commit

- [ ] `flutter analyze` clean
- [ ] `flutter test` vert
- [ ] `build_runner` relancé si modèle/Retrofit touché
- [ ] Strings ajoutées dans **les deux** `.arb` + `gen-l10n` relancé
- [ ] Chaque `Failure` mappée dans `_mapFailureToMessage()` du BLoC
- [ ] Pas de string/couleur/dimension hardcodée
- [ ] `FeatureScope` ferme bien son BLoC dans `dispose()` si scopé

## Langue & ton

- Commits, PR, commentaires de code en **français**.
- Code (identifiants, types) en **anglais**.
- Strings UI : sources dans `app_fr.arb`, traduites dans `app_en.arb`.

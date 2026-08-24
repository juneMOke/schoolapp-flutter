# AGENTS.md

This document provides guidance for AI coding agents to effectively contribute to this Flutter codebase.

## Quick Reference

- **Project Type:** Flutter school management app
- **Architecture:** Feature-based Clean Architecture (3-layer)
- **State Management:** BLoC (flutter_bloc)
- **DI Container:** GetIt + Injectable
- **Networking:** Dio + Retrofit
- **Local Storage:** Hive + Flutter Secure Storage
- **Routing:** GoRouter
- **Functional Programming:** dartz (Either/Left/Right pattern)
- **Test Framework:** flutter_test + bloc_test + mocktail

## Architecture Overview

### Feature-Based Structure

Each feature is a self-contained module at `lib/features/{feature_name}`:
```
auth/
├── data/
│   ├── datasources/          # Remote (Retrofit) & Local data access
│   ├── models/               # JSON serializable request/response models
│   ├── repositories/         # Implementation of domain repositories
│   └── services/             # Utilities (TokenStorageService, etc.)
├── domain/
│   ├── entities/             # Core data models (no serialization)
│   ├── repositories/         # Abstract interfaces
│   └── usecases/             # Business logic that returns Either<Failure, T>
└── presentation/
    ├── bloc/                 # {feature}_bloc.dart, {feature}_event.dart, {feature}_state.dart
    ├── pages/                # Full-screen widgets
    └── widgets/              # Reusable UI components
```

### Core Directory Structure

Shared utilities at `lib/core`:
- `di/injection.dart` - Single source of truth for DI registration
- `error/failures.dart` - Failure types for Either pattern
- `network/` - Networking helpers
- `theme/` - Theme configuration
- `widgets/` - Reusable UI components

## Data Flow Pattern

The project strictly follows functional FP with the Either pattern:

```
UseCase.call() → Repository.method() → Either<Failure, Entity>
   ↓
Bloc catches Either result with result.fold()
   ↓
Bloc emits new State (loading, success, error)
   ↓
Widget listens to BlocListener/BlocBuilder
```

**Key Pattern:** All async operations that can fail return `Future<Either<Failure, T>>`. Use `.fold()` to extract success/failure.

Example from `auth_repository_impl.dart`:
```dart
Future<Either<Failure, AuthSession>> login({...}) async {
  try {
    final response = await remoteDataSource.login(...);
    final session = response.toAuthSession();
    await localDataSource.saveSession(session);
    return Right(session);  // Success
  } on DioException catch (e) {
    if (e.error is Failure) return Left(e.error as Failure);
    return const Left(NetworkFailure('Network error occurred'));
  }
}
```

## State Management Details

### BLoC Pattern with Events

Every feature BLoC uses event-driven pattern:

1. **Events** (`{feature}_event.dart`): Immutable, equatable event classes
2. **States** (`{feature}_state.dart`): Immutable state snapshots with copyWith()
3. **BLoC** (`{feature}_bloc.dart`): Handles events with `on<EventType>(_handler)` pattern

Example structure:
```dart
// AuthBloc registers event handlers in constructor
AuthBloc({required LoginUseCase loginUseCase, ...}) 
  : super(AuthState.initial()) {
  on<AuthLoginRequested>(_onAuthLoginRequested);
}

// Handler calls usecase and emits states
Future<void> _onAuthLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
  emit(state.copyWith(status: AuthStatus.loading));
  final result = await _loginUseCase(email: event.email, password: event.password);
  result.fold(
    (failure) => emit(state.copyWith(status: AuthStatus.error, errorMessage: failure.message)),
    (session) => emit(state.copyWith(status: AuthStatus.authenticated, user: session.user)),
  );
}
```

### Bloc Registration Pattern

Register BLoCs as **factories** (not singletons) in `injection.dart`:
```dart
getIt.registerFactory<AuthBloc>(
  () => AuthBloc(
    loginUseCase: getIt<LoginUseCase>(),
    // ... inject all dependencies
  ),
);
```

## Dependency Injection Deep Dive

### Registration Rules

1. **Core utilities (Dio, Storage, etc.)** → `registerLazySingleton`
2. **Data sources & Repositories** → `registerLazySingleton` (expensive operations)
3. **UseCases** → `registerFactory` (lightweight, stateless)
4. **BLoCs** → `registerFactory` (one per screen/feature scope)

### Dio Interceptor Pattern

Authentication is handled via Dio interceptor in `injection.dart`:
- Request interceptor: Adds `Authorization: Bearer {token}` if `options.extra['requiresAuth'] == true`
- Error interceptor: Maps HTTP errors (401, 403, 5xx) to Failure types
- Token is retrieved from `TokenStorageService` (wraps FlutterSecureStorage)

### Required Auth Extra

Pass authentication requirement via `RequestOptionsExtra.auth()`:
```dart
getIt.registerLazySingleton<Map<String, dynamic>>(
  () => RequestOptionsExtra.auth(),
);
```

This is used in repositories to mark requests requiring auth tokens.

## Networking & Retrofit

### API Service Definition

Retrofit services use `@RestApi()` annotation with generated implementation:

```dart
@RestApi()
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(Dio dio, {String baseUrl}) = _AuthRemoteDataSource;
  
  @POST(AppConstants.loginEndpoint)
  Future<LoginResponseModel> login(@Body() LoginRequestModel request);
  
  @POST(AppConstants.resetPasswordEndpoint)
  Future<void> resetPassword(
    @Body() ResetPasswordRequest request,
    {@Header('X-OTP-Token') required String token},
  );
}
```

After modifying, regenerate with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Model Serialization

Models use `json_serializable` for automatic JSON conversion:
```dart
@JsonSerializable()
class LoginResponseModel {
  @JsonKey(name: 'access_token')
  final String accessToken;
  
  LoginResponseModel({required this.accessToken});
  
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
}
```

## Navigation with GoRouter

### Router Architecture

Router configuration is in `lib/router/app_router.dart` with two key classes:

1. **RouterNotifier** - Listens to AuthBloc and AcademicYearContextBloc state changes to update routes dynamically
2. **GoRouter configuration** - Defines routes and redirect logic

Routes are centralized in `app_routes_names.dart`.

### Redirect Logic Pattern

Router navigates based on auth and academic-year-context states:
- Unauthenticated + splash done → Login route
- Authenticated + academic year context pending → Loading screen
- Authenticated + academic year context done → Home/App routes

## Failure Handling

Standardized failure types in `lib/core/error/failures.dart`:

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
}

// Specific failures:
InvalidCredentialsFailure     // 401 auth errors
UnauthorizedFailure           // 403 permission errors
ServerFailure                 // 5xx server errors
NetworkFailure                // Connection issues
StorageFailure                // Local storage errors
AuthFailure                   // Generic auth errors
```

## Code Generation

This project heavily relies on code generation:

### 1. Localization
```bash
flutter gen-l10n
```
Generates `AppLocalizations` class from JSON files in `lib/l10n/`.

### 2. Build Runner (Retrofit, Injectable, JSON serialization)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Run after modifying:
- Retrofit service interfaces (generates `_` implementation class)
- Models with `@JsonSerializable()` (generates `fromJson`/`toJson`)
- Dependencies with `@injectable` (if using injectable, though not currently used)

### 3. When Build Runner Fails
- Delete `.dart_tool/build` folder
- Run `flutter clean`
- Re-run build_runner

## Testing

### Test Structure

Tests mirror feature structure in `test/features/{feature}`:
```
test/features/auth/
├── data/              # Repository and datasource tests
└── presentation/bloc/ # BLoC tests with bloc_test
```

### BLoC Testing Pattern

```dart
void main() {
  late MockLoginUseCase mockLoginUseCase;
  
  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
  });
  
  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when login succeeds',
      build: () => AuthBloc(loginUseCase: mockLoginUseCase),
      act: (bloc) {
        when(() => mockLoginUseCase(...)).thenAnswer((_) async => const Right(tSession));
        bloc.add(AuthLoginRequested(email: 'test@test.com', password: 'pass'));
      },
      expect: () => [
        AuthState.initial().copyWith(status: AuthStatus.loading),
        AuthState.initial().copyWith(status: AuthStatus.authenticated, user: tSession.user),
      ],
    );
  });
}
```

### Mock Pattern

Use `mocktail` for mocking:
```dart
class MockLoginUseCase extends Mock implements LoginUseCase {}

// In tests
when(() => mockUseCase.call(...)).thenAnswer((_) async => const Right(entity));
```

## Critical Integration Points

### 1. Academic Year Context Flow

The app resolves its academic context via `AcademicYearContextBloc` (`lib/features/academic_year/`), which replaced the old `bootstrap` module. On `AuthStatus.authenticated` it:
- Reads the academic year + school levels/groups 100% locally from the already-synced Inscription referential (`ref_academic_years`/`ref_school_level_groups`/`ref_school_levels`), scoped by school (`CurrentUserContext`)
- Triggers a network pull only if the referential is absent locally (never a speculative remote fetch while offline)
- Blocks navigation until resolved (`blocksNavigation`/`hasBlockingFailure`, same role the old `BootstrapBloc` played)

This ensures data consistency before showing enrolled students/classes. Feature scopes resolve their own independent instance (`registerFactory`) for local reads; a single global instance (provided in `main.dart`) drives the navigation gate.

### 2. Authentication Session Flow

1. App initializes with `AuthCheckRequested` event
2. Checks if stored token is valid
3. If valid, loads user info; if invalid, clears session
4. Auth state change triggers academic year context resolution (`AcademicYearContextRequested`)

### 3. Token Lifecycle

- Token stored in `FlutterSecureStorage` via `TokenStorageService`
- Token validity checked on app start (JWT expiry)
- Invalid token triggers logout
- New token saved after login

## Project-Specific Patterns & Conventions

### 1. Entity vs Model Distinction

- **Entities** (domain layer): Pure data, no JSON serialization, immutable
- **Models** (data layer): JSON serializable versions of entities, use `toEntity()` to convert

Pattern: `Model.toEntity() → Entity` and `Model.fromEntity()` for reverse

### 2. UseCase Callable Pattern

All usecases implement a single entry point:
```dart
class LoginUseCase {
  Future<Either<Failure, AuthSession>> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}

// Usage
final result = await loginUseCase(email: 'test@test.com', password: 'pass');
```

### 3. Request/Response Models

API models are separate from domain entities:
- `LoginRequestModel` - Sent to API
- `LoginResponseModel` - Received from API
- `AuthSession` - Internal domain entity

This allows independent evolution of API contracts vs app logic.

### 4. State Status Enums

BLoCs use status enums for fine-grained state management:
```dart
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  // ...
}
```

## États partagés (chargement / vide / erreur)

Toute zone de résultats (liste, tableau, panneau) **réutilise** la même
anatomie d'état. Pas de spinner ni de `StateCard` ad hoc : on branche les trois
widgets partagés (règle non-négociable #10 de CLAUDE.md).

| État | Widget partagé | Emplacement | Points clés |
|---|---|---|---|
| Chargement | `EteeloListSkeleton` (s'appuie sur `EteeloSkeletonBox`) | `lib/core/components/skeletons/` | Squelette « roster » (avatar + identité 2 lignes + pilules) qui conserve l'anatomie réelle. `reduced-motion` respecté (pas de shimmer si `disableAnimations`). `aria-busy` via `Semantics(liveRegion, label)` — passer le libellé i18n via `semanticsLabel`. |
| Vide | `EteeloEmptyResult` | `lib/core/widgets/eteelo_empty_result.dart` | Médaillon **pointillé** + titre + message + action(s). L'action propose une **issue** (ex. présence vide → renvoi vers Composition via `NavigationBloc`). |
| Erreur | `EteeloErrorResult` | `lib/core/widgets/eteelo_error_result.dart` | Médaillon + titre + message + action, piloté par `EteeloErrorType`. |

### Anatomie d'erreur — 4 types (`EteeloErrorType`)

| Type | Icône | Teinte | Action |
|---|---|---|---|
| `network` | `power_off_rounded` (unplug) | bleu ardoise | Réessayer (manuelle) |
| `unauthorized` (401) | `lock_outline_rounded` | ambre | Se reconnecter |
| `forbidden` (403) | `gpp_bad_rounded` (shield-alert) | ambre | Contacter l'administrateur — **jamais « Réessayer »** |
| `server` (500) | `dns_rounded` (server-crash) | rouge | Réessayer + code incident (`incidentCodeLabel`) |

### Convention par feature

Chaque feature expose un **wrapper mince** `XxxResultsErrorState` qui mappe son
`XxxErrorType` (issu de `_mapFailureToErrorType`) vers `EteeloErrorType`, fournit
les chaînes i18n (titre/message/action) et câble les callbacks
(`onRetry` / `onReconnect` / `onContactAdmin`). Idem `XxxResultsEmptyState`.

- **Référence** : `lib/features/attendances/presentation/widgets/states/`
  (présence/appel) et `lib/features/enrollment/presentation/widgets/states/`.
- **Convention de mapping** (interceptor Dio + BLoCs) : HTTP **401** →
  `InvalidCredentialsFailure` → `unauthorized` (session expirée / Se reconnecter) ;
  HTTP **403** → `UnauthorizedFailure` → `forbidden` (accès refusé / Contacter
  l'administrateur). Mappez **les deux** dans `_mapFailureToErrorType` du BLoC,
  sinon un 403 s'affiche par erreur comme un 401.
- L'erreur s'affiche **en place** (pas de snackbar redondant pour un échec de
  chargement).

## Formulaires de recherche

### Bascule de mode (recherche bi-mode)

Une carte qui offre **deux façons de trouver la même chose** (toute une classe
ou un élève précis) porte une **bascule**, jamais deux blocs concurrents reliés
par un « OU ». Les modes s'**excluent** : chercher par classe ET par nom ne
remonterait que les élèves où les deux concordent, alors que chaque critère seul
suffisait.

| Brique | Fichier | Rôle |
|---|---|---|
| `SearchMode` + `SearchModeSwitch` | `lib/core/components/search/search_mode_switch.dart` | Enum (`level`, `identity`) et bascule : annonce « Rechercher par », onglets pleine largeur (`SegmentedTabFilter`, `expand: true`), aide du mode actif. |
| `SearchHintPill` | `lib/core/components/search/search_hint_pill.dart` | Bandeau d'aide (icône + texte). Sert à l'aide de mode **et** à la pastille propre à une feature. |
| `BiModeSearchForm` | `lib/core/components/search/bi_mode_search_form.dart` | Carte complète clé en main : bascule, champs du mode actif, actions. Utilisée par Documents, Facturation, Ré- et Pré-inscription. |
| `SearchLevelCascade` / `SearchNameFields` | `lib/core/components/search/` | Les champs de chacun des deux modes. |
| `SearchLevelModeFields` | `lib/core/components/search/search_level_mode_fields.dart` | Le mode « Par classe » au complet : la cascade **plus** l'affinage par nom. |
| `SearchRefineNameField` | `lib/core/components/search/search_refine_name_field.dart` | Affinage **facultatif** par nom, mode classe uniquement. Rapprochement partiel et insensible aux accents, sur la colonne « Nom ». |

Règles :

- **`level` est le premier mode**, `identity` le second — l'entrée par la classe
  est la plus courante.
- Seuls les critères du **mode actif** partent dans la requête ; ceux de l'autre
  restent **saisis** (y revenir ne coûte pas de tout retaper) mais ne voyagent
  jamais. Sans cela une classe entière serait réduite en douce à un nom oublié
  dans un champ replié.
- L'exclusivité porte sur le critère qui **ouvre** la recherche, pas sur tout
  critère. Le mode classe garde un **affinage par nom facultatif** : la classe
  ouvre, le nom restreint — sinon retrouver quelqu'un dans une classe de
  soixante obligerait à connaître ses trois noms. Il n'arme jamais la recherche
  à lui seul.
- Sans référentiel (`options` vide), la carte **ouvre sur l'identité** : « Par
  classe » n'y offrirait que deux listes grisées. Le mode par défaut suit le
  référentiel tant que l'utilisateur n'a rien engagé, jamais après.
- Le bouton « Rechercher » n'est armé que par le mode actif.
- Les libellés de la bascule et ses aides sont **partagés** (`searchModeByClass`,
  `searchModeByIdentity`, `searchModeClassHint`, `searchModeIdentityHint`…) : un
  même geste ne s'appelle pas autrement d'un module à l'autre. Une feature ne
  fournit que son titre, son sous-titre et les libellés de sa cascade.
- L'aide du mode actif **nomme l'autre mode** : c'est la porte de sortie de qui
  est entré par la mauvaise.
- Un formulaire dont les deux modes sont **additifs** (Résultats : le mode élève
  a besoin de la classe et de la période pour calculer) garde sa propre bascule
  et n'entre pas dans `BiModeSearchForm`.

### Rattacher une fiche déjà connue (étape Tuteurs)

Le point d'entrée d'une recherche de rattachement se pose **dans la carte qu'il
va remplacer**, jamais dans l'en-tête de l'étape.

- `GuardianLinkExistingBanner` ouvre le corps de la carte dépliée, avant les
  champs — là où l'utilisateur s'apprête à ressaisir ce qui existe déjà. Une
  loupe d'en-tête ne se trouvait pas, et ne désignait aucun tuteur.
- La fiche retenue **remplace** la carte d'où l'appel est parti
  (`_linkFoundParent`) : son id devient l'id RÉEL de la fiche (ce qui marque le
  lien pour la garde d'unicité), l'identité passe en lecture seule, et le
  brouillon est réécrit dans la foulée. Le **lien de parenté survit** au
  remplacement : il appartient à cet élève, pas à la fiche parent.
- Le bandeau disparaît d'une carte déjà rattachée — il n'aurait plus rien à
  proposer.

### Un refus de doublon propose la sortie

Quand la garde d'unicité téléphone refuse une écriture, l'étape ne se contente
pas du message : `showGuardianPhoneConflictDialog` relance la recherche **sur le
numéro refusé** et propose la ou les fiches qui le portent. « Utiliser cette
fiche » remplace la carte fautive ; « Corriger le numéro » ne referme que la
popin (rien n'a été écrit — l'enregistrement a déjà échoué).

⚠️ **La fiche proposée vient de la garde, pas de la recherche.**
`ParentPhoneConflictException` connaît l'id du coupable ; il voyage jusqu'à
l'UI (`DuplicateParentPhoneFailure.existingParentId` →
`EnrollmentDraftGuardianPhoneConflict`) et c'est LUI qui est pré-désigné. La
recherche rejouée ne sert qu'à peupler la liste, et ses résultats sont
re-filtrés par `PhoneNumberFormat.sameNumber` : son `LIKE` sur les chiffres est
un sur-ensemble strict de la comparaison canonique qui a refusé l'écriture, un
numéro hérité voisin y remonterait à côté du vrai coupable. À plusieurs
porteurs sans id nommé, **rien n'est pré-coché** — un rattachement porte
`isLinkedToExisting: true`, donc `upsertDraftGuardianParent` sort par la
branche « fiche existante » sans rejouer la garde : personne en aval ne
rattraperait le mauvais parent.

Deux cas gardent le simple message, parce qu'aucune fiche existante n'y est en
cause : quand **deux cartes du même dossier** portent le numéro (le doublon est
interne, aucune ne peut être désignée), et quand plus aucune carte ne le porte.
C'est pourquoi `EnrollmentDraftGuardianPhoneConflict` transporte le **numéro**
en plus du message : sans lui, la carte fautive serait indésignable.

### Formatage des champs texte

La capitalisation est le **défaut** d'`EteeloTextInput` : c'est l'exception qui
se déclare, pas la règle (`lib/core/formatters/text_capitalization_formatters.dart`).

| Règle | Formatter | Pour |
|---|---|---|
| Chaque mot | `WordCapitalizationInputFormatter` | Identités et lieux — « Jean-Pierre Mokili ». Le trait d'union et l'apostrophe ouvrent un mot. |
| Première lettre | `SentenceCapitalizationInputFormatter` | Textes libres — « Absence non justifiée ». La première **lettre**, pas le premier caractère. |

`EteeloTextInput.capitalization` vaut `auto` par défaut et se résout sur la
**forme réelle** du champ : `email` / `phone` / `number` → rien ; `multiline`
**ou toute hauteur > 1 ligne** → phrase ; le reste → mot par mot. La hauteur
compte autant que le type de clavier, sans quoi un `maxLines: 4` oublié rendrait
« Absence Non Justifiée ». Un champ qui ne doit rien capitaliser (matricule,
code, référence) le déclare avec `EteeloTextCapitalization.none`.

⚠️ Les formatters s'appliquent à **chaque frappe** : une lettre rabaissée à la
main est re-capitalisée au caractère suivant. « de Souza » redevient « De
Souza », « van der Berg » est inatteignable. Comportement historique du champ
nom, conservé ; un champ qui doit accepter une particule passe en `none`.

Les deux formatters ne posent **que** des majuscules : ils ne rabaissent jamais
une capitale saisie à la main (sigles, particules corrigées). Les
`inputFormatters` de l'appelant sont conservés et passent **avant** la
capitalisation. Pour un champ qui n'est pas un `EteeloTextInput` (`TextField` /
`TextFormField` brut), passer le formatter explicitement.

## Common Workflows

### Creating a New Feature

1. **Create feature directory** under `lib/features/{feature}`
2. **Define domain layer** (entities, repositories, usecases)
3. **Implement data layer** (models, datasources, repository implementations)
4. **Create presentation** (BLoC with events/states, pages, widgets)
5. **Register in DI** (`lib/core/di/injection.dart`)
6. **Add routes** (`lib/router/app_router.dart`)
7. **Write tests** mirroring structure in `test/features/{feature}`

### Running the App

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run

# Première fois après clone — activer les hooks locaux Git
bash scripts/install_git_hooks.sh
```

### Git Hooks locaux

Le projet fournit des hooks Git dans `.githooks/` :

| Hook | Déclencheur | Vérifications |
|---|---|---|
| `pre-commit` | `git commit` | Format Dart (auto-stage) + motion tokens check |
| `pre-push` | `git push` | `flutter analyze` + `flutter test` |

Activation (une seule fois après clone) :
```bash
bash scripts/install_git_hooks.sh
```

Bypass en urgence : `git commit --no-verify` / `git push --no-verify`.

### Debugging Tips

- **BLoC debugging**: Use `flutter_bloc_devtools` to inspect state transitions
- **Network debugging**: Check Dio interceptors in injection.dart
- **Storage issues**: `TokenStorageService.readAuthSession()` to inspect stored data
- **Route issues**: Check `RouterNotifier._snapshot` in `app_router.dart`

## Gotchas & Pitfalls

1. **Always check Either.fold()** - Don't unwrap Left/Right directly; use `.fold()` to handle both
2. **BLoC registration must be factory** - Using singleton causes shared state across screens
3. **Run build_runner after Retrofit changes** - Generated `_` class won't update automatically
4. **Equatable extends for copyWith()** - All state/event classes must extend Equatable for proper comparison
5. **Token expiry check** - JWT validation happens at app start; expired tokens trigger logout
6. **Academic year context blocks navigation** - Router won't show app routes until `AcademicYearContextBloc` resolves (reads local referential, pulls only if absent)
7. **Model → Entity conversion** - Always convert API models to entities in repositories, not in BLoCs
8. **Async operations in BLoC** - Use handlers (`on<Event>(_handler)`) pattern, not setState
9. **Authentication required marker** - Repositories must pass `requiredAuth` extra to Dio for auto-token injection
10. **Local storage persistence** - Offline data lives in the SQLCipher database (`lib/core/database/`); ensure migrations are added in `app_database.dart` when the schema changes

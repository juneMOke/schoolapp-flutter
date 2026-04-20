# GitHub Copilot Instructions — school_app_flutter

This is a **Flutter school management app** using **Feature-based Clean Architecture**.
Always read `AGENTS.md` at the project root for the full reference guide.

## Stack

- **State:** flutter_bloc (BLoC pattern with Events/States)
- **DI:** GetIt — all registrations in `lib/core/di/injection.dart`
- **Network:** Dio + Retrofit (`@RestApi()` + code generation)
- **Storage:** Hive (bootstrap cache) + FlutterSecureStorage (tokens)
- **Router:** GoRouter — config in `lib/router/app_router.dart`
- **FP:** dartz — all async ops return `Future<Either<Failure, T>>`

## Non-Negotiable Rules

1. **Either pattern everywhere** — use `.fold()`, never unwrap Left/Right directly
2. **BLoCs = `registerFactory`** in injection.dart, never singleton
3. **Models → Entities in repositories** — call `.toEntity()` before returning to domain
4. **Auth requests** — pass `requiredAuth: getIt<Map<String, dynamic>>()` to repositories needing a token
5. **After any Retrofit/JSON model change** → run `flutter pub run build_runner build --delete-conflicting-outputs`
6. **No hardcoded strings** — all UI text via `AppLocalizations` (`lib/l10n/app_fr.arb` + `app_en.arb`)
7. **No hardcoded colors/styles/dimensions** — use `AppColors`, `AppTextStyles`, `AppDimensions` from `lib/core/constants/`
8. **No magic numbers or raw URLs** — use `AppConstants` for endpoints, `AppDimensions` for spacing/sizes

## Code Quality Principles (KISS · SOLID · DRY)

- **Single Responsibility** — one widget = one responsibility; split into small reusable widgets in `presentation/widgets/` rather than building everything inside a page
- **DRY** — extract any repeated UI block into a widget, any repeated logic into a UseCase or helper
- **KISS** — prefer simple, readable code over clever one-liners; each function/method should do one thing
- **Open/Closed** — extend behavior via new UseCases or BLoC events, not by modifying existing ones
- **Depend on abstractions** — always inject the abstract repository interface, never the concrete implementation

## Feature Structure (replicate for every new feature)

```
lib/features/{name}/
  data/datasources/     ← @RestApi() Retrofit class + local source
  data/models/          ← @JsonSerializable() models with toEntity()
  data/repositories/    ← impl of domain repository
  domain/entities/      ← pure Dart, no JSON
  domain/repositories/  ← abstract interface
  domain/usecases/      ← single call() method, returns Either
  presentation/bloc/    ← *_bloc.dart, *_event.dart, *_state.dart
  presentation/pages/   ← full-screen widgets, thin — delegate to widgets/
  presentation/widgets/ ← small, reusable, single-purpose widgets
```

## Centralized Constants (never inline)

| File | Contains |
|------|----------|
| `lib/core/constants/app_constants.dart` | API base URL, endpoints, Hive keys |
| `lib/core/constants/app_colors.dart` | All colors |
| `lib/core/constants/app_text_styles.dart` | All text styles |
| `lib/core/constants/app_dimensions.dart` | Spacing, border radius, icon sizes |
| `lib/core/theme/app_theme.dart` | ThemeData configuration |

## Localization (l10n)

- **Every visible string** must be defined in `lib/l10n/app_fr.arb` **and** `lib/l10n/app_en.arb`
- Access via `context.l10n.yourKey` or `AppLocalizations.of(context)!.yourKey`
- Regenerate after editing `.arb` files: `flutter gen-l10n`
- Never use hardcoded `'string'` literals inside Widget `build()` methods

## Widget Decomposition Rules

- Pages (`*_page.dart`) are **thin** — they connect the BLoC to the UI and delegate to widgets
- Extract any widget taller than ~40 lines into its own file in `presentation/widgets/`
- Name widgets after what they represent: `EnrollmentStatusBadge`, `StudentInfoCard`, not `Widget1`
- Prefer `const` constructors on all stateless widgets

## Data Flow (strict order)

```
Widget → add(Event) → Bloc.on<Event>() → UseCase.call()
       → Repository.method() → DataSource → Either<Failure, T>
       → fold() → emit(State)
```

## DI Registration Order (injection.dart)
  
```
LazySingleton: Dio, FlutterSecureStorage, Hive Box, TokenStorageService
LazySingleton: DataSources, Repositories
Factory:       UseCases, BLoCs
```

## Failure Types (`lib/core/error/failures.dart`)

```dart
InvalidCredentialsFailure  // 401
UnauthorizedFailure        // 403
ServerFailure              // 5xx
NetworkFailure             // connection issues
StorageFailure             // Hive / SecureStorage
AuthFailure                // generic auth
```

## Key Files

| File | Role |
|------|------|
| `lib/core/di/injection.dart` | All DI registrations |
| `lib/router/app_router.dart` | GoRouter + RouterNotifier |
| `lib/router/app_routes_names.dart` | Route name constants |
| `lib/core/error/failures.dart` | All Failure types |
| `lib/main.dart` | App bootstrap, BLoC wiring, auth → bootstrap trigger |
| `test/features/auth/presentation/bloc/auth_bloc_test.dart` | BLoC test reference |

## Performance & Safety

- **`buildWhen`/`listenWhen`** — filter BlocBuilder/BlocListener rebuilds to the exact fields that changed; avoids full-tree rebuilds on unrelated state updates
  ```dart
  BlocBuilder<AuthBloc, AuthState>(
    buildWhen: (prev, curr) => prev.status != curr.status,
    builder: (context, state) { ... },
  )
  ```
- **`mounted` guard after `await`** — always check `if (!mounted) return;` after any `await` in a `StatefulWidget` method to avoid using a disposed `BuildContext`
- **l10n access pattern** — declare once at the top of `build()`, never call `AppLocalizations.of(context)!` inline multiple times:
  ```dart
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ...
  }
  ```
- **Extensions on domain/enum types** — prefer extension methods over helper functions or switch statements scattered in the UI. See `EnrollmentStatusColor` on `EnrollmentStatus` and `BootstrapOperationX` on `BootstrapOperation` as references.

## Project-Specific Patterns

### FeatureScope — BLoC scoping per feature subtree
When a feature needs its own BLoC instances scoped to a navigation subtree (not app-wide), wrap it in a `*FeatureScope` StatefulWidget that instantiates BLoCs in `initState` and closes them in `dispose`. See `EnrollmentFeatureScope` as reference.

```dart
// ✅ correct — BLoC scoped to feature subtree
class MyFeatureScope extends StatefulWidget { ... }
class _State extends State<MyFeatureScope> {
  late final MyBloc _bloc;
  @override void initState() { _bloc = getIt<MyBloc>(); super.initState(); }
  @override void dispose() { _bloc.close(); super.dispose(); }
}
// ❌ wrong — never let a factory BLoC leak without closing it
```

### copyWith sentinel for nullable fields
States with nullable fields use a `_undefined` sentinel to distinguish "not provided" from explicit `null`:
```dart
const _undefined = Object();
State copyWith({ Object? user = _undefined }) => State(
  user: identical(user, _undefined) ? this.user : user as User?,
);
```
Always replicate this pattern when adding nullable fields to a State.

### Equatable props — mandatory on events with fields
Every Event or State subclass with fields **must** override `props`. Missing `props` breaks BLoC deduplication and `blocTest` equality checks.

```dart
class AuthLoginRequested extends AuthEvent {
  final String email;
  @override List<Object?> get props => [email]; // ← mandatory
}
```

## Bootstrap ↔ Auth Coupling (main.dart)

```
AuthStatus.authenticated   → BootstrapBloc.add(BootstrapRemoteCurrentYearRequested)
                           → BootstrapBloc.add(BootstrapRemotePreviousYearRequested)
AuthStatus.unauthenticated → BootstrapBloc.add(BootstrapResetRequested)
```
Router waits for `bootstrapBloc.state.blocksNavigation == false` before showing app routes.

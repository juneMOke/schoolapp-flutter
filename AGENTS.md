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

1. **RouterNotifier** - Listens to AuthBloc and BootstrapBloc state changes to update routes dynamically
2. **GoRouter configuration** - Defines routes and redirect logic

Routes are centralized in `app_routes_names.dart`.

### Redirect Logic Pattern

Router navigates based on auth and bootstrap states:
- Unauthenticated + splash done → Login route
- Authenticated + bootstrap pending → Loading screen
- Authenticated + bootstrap done → Home/App routes

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

### 1. Bootstrap Flow

The app starts with `BootstrapBloc` that:
- Loads cached data from local storage (Hive)
- Fetches fresh data after authentication
- Blocks navigation during bootstrap

This ensures data consistency before showing enrolled students/classes.

### 2. Authentication Session Flow

1. App initializes with `AuthCheckRequested` event
2. Checks if stored token is valid
3. If valid, loads user info; if invalid, clears session
4. Auth state change triggers bootstrap data load

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
6. **Bootstrap blocks navigation** - Router won't show app routes until bootstrap completes
7. **Model → Entity conversion** - Always convert API models to entities in repositories, not in BLoCs
8. **Async operations in BLoC** - Use handlers (`on<Event>(_handler)`) pattern, not setState
9. **Authentication required marker** - Repositories must pass `requiredAuth` extra to Dio for auto-token injection
10. **Local storage persistence** - Bootstrap uses Hive box; ensure migrations are run in `injection.dart`

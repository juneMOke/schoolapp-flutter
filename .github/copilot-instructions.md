# AGENTS.md — school_app_flutter

> Fichier de référence pour GitHub Copilot et tout agent IA contribuant à ce projet.
> Lire entièrement avant toute génération de code.

---

## 1. Contexte rapide

- **Framework** : Flutter (Dart)
- **Architecture** : Feature-based Clean Architecture
- **State** : flutter_bloc (BLoC pattern strict — Events / States)
- **DI** : GetIt — toutes les registrations dans `lib/core/di/injection.dart`
- **Network** : Dio + Retrofit (`@RestApi()` + code generation via build_runner)
- **Storage** : Hive (bootstrap cache) + FlutterSecureStorage (tokens)
- **Router** : GoRouter — config dans `lib/router/app_router.dart`
- **FP** : dartz — toutes les opérations async retournent `Future<Either<Failure, T>>`

---

## 2. Structure physique du projet

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # base URL, endpoints, Hive keys
│   │   ├── app_colors.dart           # toutes les couleurs
│   │   ├── app_text_styles.dart      # tous les styles de texte
│   │   └── app_dimensions.dart       # spacing, border radius, icon sizes
│   ├── di/
│   │   └── injection.dart            # toutes les registrations GetIt
│   ├── error/
│   │   └── failures.dart             # tous les types Failure
│   ├── network/
│   │   └── dio_client.dart           # configuration Dio
│   └── theme/
│       └── app_theme.dart            # ThemeData
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/          # AuthRemoteDataSource (@RestApi)
│   │   │   ├── models/               # AuthModel (@JsonSerializable)
│   │   │   └── repositories/         # AuthRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/             # Auth (pure Dart)
│   │   │   ├── repositories/         # AuthRepository (abstract)
│   │   │   └── usecases/             # LoginUseCase, LogoutUseCase...
│   │   └── presentation/
│   │       ├── bloc/                 # auth_bloc.dart, auth_event.dart, auth_state.dart
│   │       ├── pages/                # LoginPage, RegisterPage...
│   │       └── widgets/              # AuthFormField, OtpInput...
│   │
│   ├── bootstrap/
│   ├── student/
│   ├── enrollment/
│   ├── attendance/
│   └── {nouveau_module}/             # reproduire cette structure exacte
│
├── l10n/
│   ├── app_fr.arb                    # strings FR (source de vérité)
│   └── app_en.arb                    # strings EN
│
├── router/
│   ├── app_router.dart               # GoRouter + RouterNotifier
│   └── app_routes_names.dart         # constantes des noms de routes
│
└── main.dart                         # bootstrap, BLoC wiring, auth → bootstrap trigger
```

---

## 3. Règles non négociables

1. **Either pattern partout** — utiliser `.fold()`, jamais unwrap Left/Right directement
2. **BLoCs = `registerFactory`** dans injection.dart, jamais singleton
3. **Models → Entities dans les repositories** — appeler `.toEntity()` avant de retourner au domain
4. **Auth requests** — passer `requiredAuth: getIt<Map<String, dynamic>>()` aux repositories nécessitant un token
5. **Après tout changement Retrofit/JSON** → lancer `flutter pub run build_runner build --delete-conflicting-outputs`
6. **Zéro string hardcodée** — tout texte UI via `AppLocalizations` (`app_fr.arb` + `app_en.arb`)
7. **Zéro couleur/style/dimension hardcodée** — utiliser `AppColors`, `AppTextStyles`, `AppDimensions`
8. **Zéro magic number ou URL brute** — utiliser `AppConstants` pour les endpoints, `AppDimensions` pour les espacements
9. On vise des fichiers de près de 250 lignes maximum, si plus on refactor en composants

---

## 4. Data Flow — ordre strict à respecter

```
Widget
  → add(Event)
  → Bloc.on<Event>()
  → UseCase.call()
  → Repository.method()          ← interface domain, jamais l'impl directement
  → DataSource (Retrofit/Hive)
  → Either<Failure, T>
  → fold()
  → emit(State)
```

**Jamais** : appel réseau direct dans un BLoC ou un widget.
**Jamais** : logique métier dans un DataSource.

---

## 5. Pattern Retrofit — data source obligatoire

```dart
@RestApi()
abstract class StudentRemoteDataSource {
  factory StudentRemoteDataSource(Dio dio, {String baseUrl}) =
      _StudentRemoteDataSource;

  @GET(AppConstants.studentById)          // endpoint défini dans AppConstants
  Future<StudentModel> getStudentById(
    @Header('Authorization') String token,
    @Path('id') String id,
  );

  @POST(AppConstants.createStudent)
  Future<StudentModel> createStudent(
    @Header('Authorization') String token,
    @Body() CreateStudentRequest body,
  );

  @GET(AppConstants.students)
  Future<List<StudentModel>> getStudents(
    @Header('Authorization') String token,
    @Query('schoolId') String schoolId,
    @Query('page') int page,
  );
}
```

### Enregistrement dans injection.dart
```dart
// DataSource
getIt.registerLazySingleton<StudentRemoteDataSource>(
  () => StudentRemoteDataSource(getIt<Dio>()),
);

// Repository
getIt.registerLazySingleton<StudentRepository>(
  () => StudentRepositoryImpl(
    remoteDataSource: getIt<StudentRemoteDataSource>(),
  ),
);

// UseCases
getIt.registerFactory(() => GetStudentByIdUseCase(getIt<StudentRepository>()));
getIt.registerFactory(() => CreateStudentUseCase(getIt<StudentRepository>()));

// BLoC
getIt.registerFactory(() => StudentBloc(
  getStudentById: getIt<GetStudentByIdUseCase>(),
  createStudent: getIt<CreateStudentUseCase>(),
));
```

### Ordre obligatoire dans injection.dart
```
1. LazySingleton : Dio, FlutterSecureStorage, Hive Box, TokenStorageService
2. LazySingleton : DataSources
3. LazySingleton : Repositories
4. Factory       : UseCases
5. Factory       : BLoCs
```

---

## 6. Pattern UseCase — template obligatoire

```dart
// UseCase simple (un seul paramètre ou aucun)
class GetStudentByIdUseCase {
  final StudentRepository repository;
  GetStudentByIdUseCase(this.repository);

  Future<Either<Failure, Student>> call(String id) =>
      repository.getStudentById(id);
}

// UseCase avec paramètres multiples → Params object obligatoire
class GetStudentByIdUseCase {
  final StudentRepository repository;
  GetStudentByIdUseCase(this.repository);

  Future<Either<Failure, Student>> call(GetStudentByIdParams params) =>
      repository.getStudentById(params.id);
}

class GetStudentByIdParams extends Equatable {
  final String id;
  const GetStudentByIdParams({required this.id});

  @override List<Object?> get props => [id];
}
```

---

## 7. Pattern Model — mapping OpenAPI → Dart

### Types OpenAPI → types Dart
| OpenAPI | Dart |
|---|---|
| `string` | `String` |
| `string (uuid)` | `String` |
| `string (date)` | `DateTime` |
| `string (date-time)` | `DateTime` |
| `integer` | `int` |
| `number` | `double` |
| `boolean` | `bool` |
| `array` | `List<T>` |
| champ nullable (`nullable: true`) | `T?` |

### Template modèle
```dart
@JsonSerializable()
class StudentModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;       // nullable → DateTime?

  const StudentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) =>
      _$StudentModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentModelToJson(this);

  // Conversion vers l'entité domain — obligatoire
  Student toEntity() => Student(
    id: id,
    firstName: firstName,
    lastName: lastName,
    dateOfBirth: dateOfBirth,
  );

  @override List<Object?> get props => [id, firstName, lastName, dateOfBirth];
}
```

**Règle** : Après tout changement de model → `flutter pub run build_runner build --delete-conflicting-outputs`

---

## 8. Pattern BLoC — template complet

### Event
```dart
sealed class StudentEvent extends Equatable {
  const StudentEvent();
}

class StudentFetchRequested extends StudentEvent {
  final String id;
  const StudentFetchRequested({required this.id});

  @override List<Object?> get props => [id]; // obligatoire si champs présents
}
```

### State
```dart
enum StudentStatus { initial, loading, success, error }

// Sentinel pour les champs nullable dans copyWith
const _undefined = Object();

class StudentState extends Equatable {
  final StudentStatus status;
  final Student? student;
  final String? errorMessage;

  const StudentState({
    this.status = StudentStatus.initial,
    this.student,
    this.errorMessage,
  });

  StudentState copyWith({
    StudentStatus? status,
    Object? student = _undefined,       // sentinel pour nullable
    Object? errorMessage = _undefined,
  }) => StudentState(
    status: status ?? this.status,
    student: identical(student, _undefined) ? this.student : student as Student?,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
  );

  @override List<Object?> get props => [status, student, errorMessage];
}
```

### BLoC
```dart
class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final GetStudentByIdUseCase _getStudentById;

  StudentBloc({required GetStudentByIdUseCase getStudentById})
      : _getStudentById = getStudentById,
        super(const StudentState()) {
    on<StudentFetchRequested>(_onFetchRequested);
  }

  Future<void> _onFetchRequested(
    StudentFetchRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(state.copyWith(status: StudentStatus.loading));

    final result = await _getStudentById(event.id);

    result.fold(
      (failure) => emit(state.copyWith(
        status: StudentStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (student) => emit(state.copyWith(
        status: StudentStatus.success,
        student: student,
      )),
    );
  }

  // Obligatoire dans chaque BLoC — mapper les Failure en message lisible
  String _mapFailureToMessage(Failure failure) => switch (failure) {
    NetworkFailure() => 'Vérifiez votre connexion internet',
    UnauthorizedFailure() => 'Accès non autorisé',
    InvalidCredentialsFailure() => 'Identifiants incorrects',
    ServerFailure() => 'Erreur serveur, réessayez plus tard',
    StorageFailure() => 'Erreur de stockage local',
    _ => 'Une erreur est survenue',
  };
}
```

---

## 9. Pattern Widget — règles de décomposition

### Page (mince — délègue tout)
```dart
class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // déclarer une seule fois en haut

    return BlocConsumer<StudentBloc, StudentState>(
      listenWhen: (prev, curr) => prev.status != curr.status, // filtrer les rebuilds
      listener: (context, state) {
        if (state.status == StudentStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? l10n.genericError)),
          );
        }
      },
      buildWhen: (prev, curr) => prev.status != curr.status, // filtrer les rebuilds
      builder: (context, state) => switch (state.status) {
        StudentStatus.loading => const StudentLoadingWidget(),
        StudentStatus.success => StudentInfoCard(student: state.student!),
        StudentStatus.error   => StudentErrorWidget(message: state.errorMessage),
        StudentStatus.initial => const SizedBox.shrink(),
      },
    );
  }
}
```

### Règles widgets
- Pages (`*_page.dart`) : **minces** — BLoC → UI, délègue aux widgets
- Tout bloc de widget > ~40 lignes → extraire dans `presentation/widgets/`
- Nommer les widgets après ce qu'ils représentent : `EnrollmentStatusBadge`, `StudentInfoCard`
- `const` constructor sur tous les widgets stateless
- **`buildWhen`/`listenWhen`** obligatoires si rebuild partiel possible
- **`mounted` guard** après tout `await` dans un `StatefulWidget`

```dart
// mounted guard obligatoire
Future<void> _doSomething() async {
  await someAsyncOperation();
  if (!mounted) return; // ← toujours présent
  setState(() { ... });
}
```

---

## 10. Localisation — règles strictes

- Toute string visible → définie dans `app_fr.arb` **ET** `app_en.arb`
- Accès : `AppLocalizations.of(context)!.yourKey` ou `context.l10n.yourKey`
- Déclarer une seule fois en haut du `build()`, jamais inline multiple fois
- Après édition des `.arb` : `flutter gen-l10n`
- **Jamais** de string littérale dans un `build()` : `Text('Mon texte')` est interdit

---

## 11. Pattern FeatureScope — BLoC scoping par feature

Quand une feature a besoin de ses propres instances BLoC scoped à un sous-arbre de navigation :

```dart
// ✅ Correct — BLoC scopé au sous-arbre de la feature
class StudentFeatureScope extends StatefulWidget {
  final Widget child;
  const StudentFeatureScope({required this.child, super.key});

  @override State<StudentFeatureScope> createState() => _StudentFeatureScopeState();
}

class _StudentFeatureScopeState extends State<StudentFeatureScope> {
  late final StudentBloc _studentBloc;

  @override
  void initState() {
    super.initState();
    _studentBloc = getIt<StudentBloc>();
  }

  @override
  void dispose() {
    _studentBloc.close(); // fermeture obligatoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [BlocProvider.value(value: _studentBloc)],
    child: widget.child,
  );
}

// ❌ Interdit — factory BLoC sans fermeture
// Ne jamais laisser un factory BLoC leak sans close()
```

Voir `EnrollmentFeatureScope` comme référence dans le projet.

---

## 12. Failure types (`lib/core/error/failures.dart`)

```dart
InvalidCredentialsFailure  // 401 — identifiants incorrects
UnauthorizedFailure        // 403 — accès interdit
ServerFailure              // 5xx — erreur serveur
NetworkFailure             // pas de connexion
StorageFailure             // Hive / SecureStorage
AuthFailure                // auth générique
```

**Chaque BLoC** doit implémenter `_mapFailureToMessage(Failure)` couvrant tous ces types.

---

## 13. Bootstrap ↔ Auth coupling (`main.dart`)

```
AuthStatus.authenticated   → BootstrapBloc.add(BootstrapRemoteCurrentYearRequested)
                           → BootstrapBloc.add(BootstrapRemotePreviousYearRequested)
AuthStatus.unauthenticated → BootstrapBloc.add(BootstrapResetRequested)
```

Le Router attend `bootstrapBloc.state.blocksNavigation == false` avant d'afficher les routes app.

**Attention** : Tout changement sur `AuthBloc` peut impacter le bootstrap et le routing. Vérifier systématiquement.

---

## 14. Extensions sur types domain/enum

Préférer les extension methods aux switch statements dispersés dans l'UI.

```dart
// ✅ Correct — extension sur le type
extension EnrollmentStatusColor on EnrollmentStatus {
  Color get color => switch (this) {
    EnrollmentStatus.active   => AppColors.success,
    EnrollmentStatus.pending  => AppColors.warning,
    EnrollmentStatus.archived => AppColors.muted,
  };
}

// Usage dans le widget
Container(color: enrollment.status.color)

// ❌ Interdit — switch inline dans le widget
Container(color: enrollment.status == EnrollmentStatus.active
    ? AppColors.success : AppColors.warning)
```

Voir `EnrollmentStatusColor` et `BootstrapOperationX` comme références dans le projet.

---

## 15. Fichiers clés

| Fichier | Rôle |
|---|---|
| `lib/core/di/injection.dart` | Toutes les registrations GetIt |
| `lib/router/app_router.dart` | GoRouter + RouterNotifier |
| `lib/router/app_routes_names.dart` | Constantes des noms de routes |
| `lib/core/error/failures.dart` | Tous les types Failure |
| `lib/main.dart` | Bootstrap, BLoC wiring, auth → bootstrap trigger |
| `test/features/auth/presentation/bloc/auth_bloc_test.dart` | Référence de test BLoC |

---

## 16. Checklist avant tout commit

- [ ] `flutter pub run build_runner build --delete-conflicting-outputs` lancé si model/retrofit modifié
- [ ] Strings UI ajoutées dans `app_fr.arb` ET `app_en.arb`, `flutter gen-l10n` relancé
- [ ] Chaque Failure mappée en message lisible dans `_mapFailureToMessage()` du BLoC
- [ ] BLoC enregistré en `registerFactory` dans `injection.dart`
- [ ] Repository : interface dans `domain/repositories/`, impl dans `data/repositories/`
- [ ] `Equatable props` définis sur tous les Events et States avec champs
- [ ] `buildWhen`/`listenWhen` ajoutés si rebuild partiel possible
- [ ] `mounted` guard présent après tout `await` dans un StatefulWidget
- [ ] Zéro string/couleur/dimension hardcodée dans les widgets
- [ ] FeatureScope fermé dans `dispose()` si BLoC scopé à un sous-arbre
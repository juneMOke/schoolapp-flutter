import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_natures_for_year_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_catalog_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_student_sheet_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/recouvrement_dashboard_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_address.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../fixtures/recovery_fixtures.dart';

/// Le banc du tableau de bord : un GetIt de test câblé comme
/// `recouvrement_v2_di.dart` — vrais cubits, dépôt et cas d'usage simulés —,
/// une année en succès et un vrai `GoRouter` pour l'adresse.
class MockRecoveryRepository extends Mock
    implements RecoveryDashboardRepository {}

class MockGetNatures extends Mock implements GetFeeNaturesForYearUseCase {}

class MockGetClassrooms extends Mock implements GetOfflineClassroomsUseCase {}

class MockCountPending extends Mock implements CountPendingPaymentsUseCase {}

class MockSearchEnrollments extends Mock
    implements SearchLocalEnrollmentsUseCase {}

class MockGetPositions extends Mock implements GetRecoveryPositionsUseCase {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _StubFeeSectionTitlesCubit extends Cubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {
  _StubFeeSectionTitlesCubit() : super(const FeeSectionTitlesState());

  @override
  Future<void> load() async {}
}

const dashboardPath = '/recouvrement/tableau-de-bord';

/// Le catalogue de l'année, dans l'ordre de l'école : la scolarité d'abord.
const catalogNatures = <({String feeCode, List<String> currencies})>[
  (feeCode: 'TUITION', currencies: ['USD']),
  (feeCode: 'SUPPLIES', currencies: ['USD']),
];

class DashboardHarness {
  final repository = MockRecoveryRepository();
  final natures = MockGetNatures();
  final classrooms = MockGetClassrooms();
  final countPending = MockCountPending();
  final academicYear = _MockAcademicYearBloc();
  final auth = _MockAuthBloc();
  GoRouter? router;

  static void registerFallbacks() {
    registerFallbackValue(const RecoveryQuestion(feeCodes: ['TUITION']));
    registerFallbackValue(
      const RecoveryStudentsQuery(
        question: RecoveryQuestion(feeCodes: ['TUITION']),
      ),
    );
    registerFallbackValue(const AcademicYearContextRequested());
  }

  void setUp() {
    RecoveryDashboardAddress.lastVisit = null;
    final getIt = GetIt.instance;
    getIt.registerFactory<RecoveryDashboardCubit>(
      () => RecoveryDashboardCubit(
        repository: repository,
        countPending: countPending,
      ),
    );
    getIt.registerFactory<RecoveryStudentsCubit>(
      () => RecoveryStudentsCubit(
        repository: repository,
        countPending: countPending,
      ),
    );
    getIt.registerFactory<RecoveryCatalogCubit>(
      () =>
          RecoveryCatalogCubit(getNatures: natures, getClassrooms: classrooms),
    );
    getIt.registerFactory<RecoveryStudentSheetCubit>(
      () => RecoveryStudentSheetCubit(
        search: MockSearchEnrollments(),
        getNatures: natures,
        getPositions: MockGetPositions(),
      ),
    );
    getIt.registerFactory<FeeSectionTitlesCubit>(
      _StubFeeSectionTitlesCubit.new,
    );
    getIt.registerSingleton<RecoveryDashboardRepository>(repository);
    getIt.registerSingleton<CountPendingPaymentsUseCase>(countPending);

    when(() => countPending()).thenAnswer((_) async => const Right(0));
    stubCatalog(catalogNatures);
    when(
      () => classrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer(
      (_) async => const Right([
        OfflineClassroom(
          id: 'c1',
          academicYearId: 'ay-1',
          schoolLevelGroupId: 'g1',
          schoolLevelId: 'lvl-1',
          name: '1ère A',
        ),
      ]),
    );
    when(
      () => repository.lastCachedQuestion(any()),
    ).thenAnswer((_) async => null);
    stubDashboard((_) => Right(recoveryDashboardFixture()));
    when(
      () => repository.students(
        any(),
        any(),
        pendingWrites: any(named: 'pendingWrites'),
      ),
    ).thenAnswer((_) async => Right(recoveryStudentsFixture()));

    whenListen(
      academicYear,
      const Stream<AcademicYearContextState>.empty(),
      initialState: AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'ay-1',
            name: '2026-2027',
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2027, 7, 1),
            current: true,
          ),
          schoolLevelGroups: const [
            SchoolLevelGroupBundle(
              group: SchoolLevelGroup(
                id: 'g1',
                name: 'Primaire',
                code: 'PRIM',
                displayOrder: 1,
              ),
              levels: [
                SchoolLevel(
                  id: 'lvl-1',
                  name: '1ère année',
                  code: 'P1',
                  displayOrder: 1,
                  splitIntoClassrooms: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.authenticated),
    );
  }

  Future<void> tearDown() async {
    RecoveryDashboardAddress.lastVisit = null;
    router?.dispose();
    await GetIt.instance.reset();
  }

  void stubCatalog(List<({String feeCode, List<String> currencies})> list) =>
      when(
        () => natures(academicYearId: any(named: 'academicYearId')),
      ).thenAnswer((_) async => Right(list));

  void stubDashboard(
    Either<Failure, RecoveryDashboard> Function(RecoveryQuestion question)
    answer,
  ) =>
      when(
        () => repository.dashboard(
          any(),
          any(),
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer(
        (inv) async => answer(inv.positionalArguments[1] as RecoveryQuestion),
      );

  /// Les questions posées au dépôt, dans l'ordre.
  List<RecoveryQuestion> askedQuestions() => verify(
    () => repository.dashboard(
      any(),
      captureAny(),
      pendingWrites: any(named: 'pendingWrites'),
    ),
  ).captured.cast<RecoveryQuestion>();

  /// Les pages de liste demandées, dans l'ordre.
  List<RecoveryStudentsQuery> askedStudents() => verify(
    () => repository.students(
      any(),
      captureAny(),
      pendingWrites: any(named: 'pendingWrites'),
    ),
  ).captured.cast<RecoveryStudentsQuery>();

  Map<String, String> get address =>
      router!.routerDelegate.currentConfiguration.uri.queryParameters;

  Future<void> pump(
    WidgetTester tester, {
    String query = '',
    Size size = const Size(1280, 1600),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    if (textScale != 1.0) {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    router = GoRouter(
      initialLocation: query.isEmpty ? dashboardPath : '$dashboardPath?$query',
      routes: [
        GoRoute(
          path: dashboardPath,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<AcademicYearContextBloc>.value(value: academicYear),
              BlocProvider<AuthBloc>.value(value: auth),
            ],
            child: const Scaffold(body: RecouvrementDashboardPage()),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }
}

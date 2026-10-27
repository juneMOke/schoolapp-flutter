import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_report.dart';
import 'package:school_app_flutter/features/hr_presence/domain/repositories/hr_attendance_stats_repository.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_attendance_report_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_dashboard_page.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../hr_presence_builders.dart';

class MockAcademicYearContextBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class MockNavigationBloc extends MockBloc<NavigationEvent, NavigationState>
    implements NavigationBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockStaffSyncSignals extends Mock implements StaffSyncSignals {}

class MockCountUnsynced extends Mock
    implements CountUnsyncedStaffAttendanceUseCase {}

/// Le serveur des statistiques, en mémoire : il retient chaque fenêtre et
/// chaque PDF demandés.
class FakeHrAttendanceStats implements HrAttendanceStatsRepository {
  HrAttendanceDashboard answer;
  Failure? failure;
  Failure? reportFailure;
  final List<DashboardWindow> asked = [];
  final List<(DashboardWindow, String)> printed = [];

  FakeHrAttendanceStats(this.answer);

  @override
  Future<Either<Failure, HrAttendanceDashboard>> dashboard(
    DashboardWindow window,
  ) async {
    asked.add(window);
    final failed = failure;
    return failed == null ? Right(answer) : Left(failed);
  }

  @override
  Future<Either<Failure, HrAttendanceReport>> report(
    DashboardWindow window, {
    String search = '',
  }) async {
    printed.add((window, search));
    final failed = reportFailure;
    if (failed != null) return Left(failed);
    return Right(
      HrAttendanceReport(
        bytes: Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]),
        fileName: 'assiduite.pdf',
      ),
    );
  }

  @override
  Future<Either<Failure, HrAttendanceAgentMonth>> agentMonth(
    String staffMemberId, {
    required String month,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, HrAttendanceAgentYear>> agentYear(
    String staffMemberId,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, HrAttendanceProfiles>> profiles(
    HrProfileScope scope,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, HrAttendanceRecap>> recap(String month) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, HrAttendanceReport>> profilesReport(
    HrProfileScope scope, {
    String search = '',
    StaffCategory? category,
    PresenceProfile? profile,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, HrAttendanceReport>> agentSheet(
    String staffMemberId, {
    String? month,
  }) => throw UnimplementedError();
}

class HrPresenceDashboardHarness {
  final FakeHrAttendanceStats server;
  final HrPresenceDashboardCubit cubit;
  final MockNavigationBloc navigation;
  final GoRouter? router;

  HrPresenceDashboardHarness({
    required this.server,
    required this.cubit,
    required this.navigation,
    this.router,
  });

  String get address =>
      router!.routerDelegate.currentConfiguration.uri.toString();
}

/// Monte le tableau de bord sur [server], vendredi 23 octobre 2026, année
/// 2026-2027 ouverte le 1er septembre.
///
/// [size] `null` : le format est déjà posé (test aux formats).
/// [permissions] `null` : sans session, la porte laisse tout passer.
/// [location] : monté sous un routeur, à cette adresse.
Future<HrPresenceDashboardHarness> pumpHrPresenceDashboard(
  WidgetTester tester, {
  FakeHrAttendanceStats? server,
  int unsynced = 0,
  Size? size = const Size(1280, 1600),
  List<String>? permissions,
  String? location,
  bool openable = false,
}) async {
  if (size != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }
  final stats = server ?? FakeHrAttendanceStats(dashboardOf());
  final signals = MockStaffSyncSignals();
  when(() => signals.watch(any())).thenReturn(() {});
  final count = MockCountUnsynced();
  when(
    () => count(
      from: any(named: 'from'),
      to: any(named: 'to'),
    ),
  ).thenAnswer((_) async => Right(unsynced));

  final cubit = HrPresenceDashboardCubit(
    getDashboard: GetHrAttendanceDashboardUseCase(stats),
    countUnsynced: count,
    signals: signals,
    now: () => DateTime.utc(2026, 10, 23, 9),
  );
  final report = HrAttendanceReportCubit(
    getReport: GetHrAttendanceReportUseCase(stats),
  );
  addTearDown(cubit.close);
  addTearDown(report.close);

  final year = MockAcademicYearContextBloc();
  whenListen(
    year,
    const Stream<AcademicYearContextState>.empty(),
    initialState: AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: AcademicYearContext(
        academicYear: AcademicYear(
          id: 'ay-1',
          name: '2026-2027',
          current: true,
          startDate: DateTime(2026, 9, 1),
        ),
        schoolLevelGroups: const [],
      ),
    ),
  );
  final navigation = MockNavigationBloc();

  final providers = <BlocProvider>[
    BlocProvider<AcademicYearContextBloc>.value(value: year),
    BlocProvider<NavigationBloc>.value(value: navigation),
    BlocProvider<HrPresenceDashboardCubit>.value(
      value: cubit..start(yearStart: DateTime(2026, 9, 1)),
    ),
    BlocProvider<HrAttendanceReportCubit>.value(value: report),
  ];
  if (permissions != null) {
    final auth = MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(state);
    whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
    providers.add(BlocProvider<AuthBloc>.value(value: auth));
  }

  // [openable] : les lignes ouvrent un agent (chevron, sous-titre long).
  final page = Scaffold(
    body: HrPresenceDashboardScreen(onOpenAgent: openable ? (_, _) {} : null),
  );
  GoRouter? router;
  if (location == null) {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: providers,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
  } else {
    router = GoRouter(
      initialLocation: location,
      routes: [GoRoute(path: '/rh-presences/:ecran', builder: (_, _) => page)],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: providers,
        child: MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }
  await tester.pump();
  await tester.pump();
  return HrPresenceDashboardHarness(
    server: stats,
    cubit: cubit,
    navigation: navigation,
    router: router,
  );
}

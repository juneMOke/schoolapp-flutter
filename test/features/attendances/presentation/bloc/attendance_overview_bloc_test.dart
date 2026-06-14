import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_granularity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_kpis.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_overview_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

class MockGetAttendanceOverviewUseCase extends Mock
    implements GetAttendanceOverviewUseCase {}

/// Failure sans mapping dedie -> doit retomber sur [AttendanceErrorType.unknown].
class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

void main() {
  late MockGetAttendanceOverviewUseCase mockUseCase;

  final tOverview = AttendanceOverview(
    context: StatsContext(
      schoolYear: '2025-2026',
      period: 'year',
      periodStart: DateTime(2025, 9, 1),
      periodEnd: DateTime(2026, 6, 30),
      generatedAt: DateTime(2026, 6, 13),
    ),
    kpis: const AttendanceKpis(
      presenceRate: 92.0,
      justifiedAbsenceRate: 5.0,
      unjustifiedAbsenceRate: 3.0,
      recordedDays: 180,
      presentDays: 166,
      justifiedAbsenceDays: 9,
      unjustifiedAbsenceDays: 5,
    ),
    evolution: const AttendanceEvolution(
      granularity: AttendanceEvolutionGranularity.month,
      currentBucketIndex: 0,
    ),
  );

  setUpAll(() => registerFallbackValue(StatsPeriod.year));

  setUp(() => mockUseCase = MockGetAttendanceOverviewUseCase());

  AttendanceOverviewBloc buildBloc() =>
      AttendanceOverviewBloc(getAttendanceOverviewUseCase: mockUseCase);

  void stubUseCase(Either<Failure, AttendanceOverview> answer) {
    when(
      () => mockUseCase(
        period: any(named: 'period'),
        month: any(named: 'month'),
        week: any(named: 'week'),
      ),
    ).thenAnswer((_) async => answer);
  }

  test('etat initial = AttendanceOverviewState() par defaut', () {
    expect(buildBloc().state, const AttendanceOverviewState());
  });

  blocTest<AttendanceOverviewBloc, AttendanceOverviewState>(
    'emet [loading, success] sur succes (periode year)',
    setUp: () => stubUseCase(Right(tOverview)),
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const AttendanceOverviewRequested(period: StatsPeriod.year)),
    expect: () => [
      const AttendanceOverviewState(
        status: AttendanceOverviewStatus.loading,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.year,
      ),
      AttendanceOverviewState(
        status: AttendanceOverviewStatus.success,
        overview: tOverview,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.year,
      ),
    ],
  );

  blocTest<AttendanceOverviewBloc, AttendanceOverviewState>(
    'succes (periode month) conserve selectedPeriod=month et selectedMonth',
    setUp: () => stubUseCase(Right(tOverview)),
    build: buildBloc,
    act: (bloc) => bloc.add(
      const AttendanceOverviewRequested(
        period: StatsPeriod.month,
        month: '2026-02',
      ),
    ),
    expect: () => [
      const AttendanceOverviewState(
        status: AttendanceOverviewStatus.loading,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.month,
        selectedMonth: '2026-02',
      ),
      AttendanceOverviewState(
        status: AttendanceOverviewStatus.success,
        overview: tOverview,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.month,
        selectedMonth: '2026-02',
      ),
    ],
    verify: (_) {
      verify(
        () => mockUseCase(
          period: StatsPeriod.month,
          month: '2026-02',
          week: null,
        ),
      ).called(1);
    },
  );

  blocTest<AttendanceOverviewBloc, AttendanceOverviewState>(
    'succes (periode week) conserve selectedPeriod=week et selectedWeek',
    setUp: () => stubUseCase(Right(tOverview)),
    build: buildBloc,
    act: (bloc) => bloc.add(
      const AttendanceOverviewRequested(
        period: StatsPeriod.week,
        week: '2026-W07',
      ),
    ),
    expect: () => [
      const AttendanceOverviewState(
        status: AttendanceOverviewStatus.loading,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.week,
        selectedWeek: '2026-W07',
      ),
      AttendanceOverviewState(
        status: AttendanceOverviewStatus.success,
        overview: tOverview,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.week,
        selectedWeek: '2026-W07',
      ),
    ],
    verify: (_) {
      verify(
        () => mockUseCase(
          period: StatsPeriod.week,
          month: null,
          week: '2026-W07',
        ),
      ).called(1);
    },
  );

  // Mapping Failure -> AttendanceErrorType (cf. attendance_failure_mapper.dart).
  final failureCases = <(Failure, AttendanceErrorType)>[
    (const NetworkFailure(), AttendanceErrorType.network),
    (const UnauthorizedFailure(), AttendanceErrorType.forbidden),
    (const InvalidCredentialsFailure(), AttendanceErrorType.invalidCredentials),
    (const ServerFailure(), AttendanceErrorType.server),
    (const ValidationFailure(), AttendanceErrorType.validation),
    (const NotFoundFailure(), AttendanceErrorType.notFound),
    (const StorageFailure(), AttendanceErrorType.storage),
    (const AuthFailure(), AttendanceErrorType.auth),
    (const _UnmappedFailure(), AttendanceErrorType.unknown),
  ];

  for (final (failure, errorType) in failureCases) {
    blocTest<AttendanceOverviewBloc, AttendanceOverviewState>(
      'emet [loading, failure(${errorType.name})] sur ${failure.runtimeType}',
      setUp: () => stubUseCase(Left(failure)),
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const AttendanceOverviewRequested(period: StatsPeriod.year)),
      expect: () => [
        const AttendanceOverviewState(
          status: AttendanceOverviewStatus.loading,
          errorType: AttendanceErrorType.none,
          selectedPeriod: StatsPeriod.year,
        ),
        AttendanceOverviewState(
          status: AttendanceOverviewStatus.failure,
          errorType: errorType,
          selectedPeriod: StatsPeriod.year,
        ),
      ],
    );
  }

  blocTest<AttendanceOverviewBloc, AttendanceOverviewState>(
    'refresh relance la requete avec la periode courante (month, 2026-02, week null)',
    setUp: () => stubUseCase(Right(tOverview)),
    build: buildBloc,
    seed: () => const AttendanceOverviewState(
      status: AttendanceOverviewStatus.success,
      selectedPeriod: StatsPeriod.month,
      selectedMonth: '2026-02',
    ),
    act: (bloc) => bloc.add(const AttendanceOverviewRefreshRequested()),
    expect: () => [
      const AttendanceOverviewState(
        status: AttendanceOverviewStatus.loading,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.month,
        selectedMonth: '2026-02',
      ),
      AttendanceOverviewState(
        status: AttendanceOverviewStatus.success,
        overview: tOverview,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.month,
        selectedMonth: '2026-02',
      ),
    ],
    verify: (_) {
      verify(
        () => mockUseCase(
          period: StatsPeriod.month,
          month: '2026-02',
          week: null,
        ),
      ).called(1);
    },
  );

  blocTest<AttendanceOverviewBloc, AttendanceOverviewState>(
    'refresh relance la requete avec la periode courante (week, 2026-W07, month null)',
    setUp: () => stubUseCase(Right(tOverview)),
    build: buildBloc,
    seed: () => const AttendanceOverviewState(
      status: AttendanceOverviewStatus.success,
      selectedPeriod: StatsPeriod.week,
      selectedWeek: '2026-W07',
    ),
    act: (bloc) => bloc.add(const AttendanceOverviewRefreshRequested()),
    expect: () => [
      const AttendanceOverviewState(
        status: AttendanceOverviewStatus.loading,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.week,
        selectedWeek: '2026-W07',
      ),
      AttendanceOverviewState(
        status: AttendanceOverviewStatus.success,
        overview: tOverview,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.week,
        selectedWeek: '2026-W07',
      ),
    ],
    verify: (_) {
      verify(
        () => mockUseCase(
          period: StatsPeriod.week,
          month: null,
          week: '2026-W07',
        ),
      ).called(1);
    },
  );

  blocTest<AttendanceOverviewBloc, AttendanceOverviewState>(
    'refresh apres erreur reinitialise errorType a none (loading et success)',
    setUp: () => stubUseCase(Right(tOverview)),
    build: buildBloc,
    seed: () => const AttendanceOverviewState(
      status: AttendanceOverviewStatus.failure,
      errorType: AttendanceErrorType.network,
      selectedPeriod: StatsPeriod.month,
      selectedMonth: '2026-02',
    ),
    act: (bloc) => bloc.add(const AttendanceOverviewRefreshRequested()),
    expect: () => [
      const AttendanceOverviewState(
        status: AttendanceOverviewStatus.loading,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.month,
        selectedMonth: '2026-02',
      ),
      AttendanceOverviewState(
        status: AttendanceOverviewStatus.success,
        overview: tOverview,
        errorType: AttendanceErrorType.none,
        selectedPeriod: StatsPeriod.month,
        selectedMonth: '2026-02',
      ),
    ],
  );
}

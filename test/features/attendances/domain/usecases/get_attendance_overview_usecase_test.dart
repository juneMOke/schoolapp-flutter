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
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_stats_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_overview_usecase.dart';

class MockAttendanceStatsRepository extends Mock
    implements AttendanceStatsRepository {}

void main() {
  late MockAttendanceStatsRepository mockRepository;
  late GetAttendanceOverviewUseCase usecase;

  final tOverview = AttendanceOverview(
    context: StatsContext(
      schoolYear: '2025-2026',
      period: 'year',
      periodStart: DateTime(2025, 9, 1),
      periodEnd: DateTime(2026, 6, 30),
      generatedAt: DateTime(2026, 6, 13),
    ),
    kpis: const AttendanceKpis(
      presenceRate: 0,
      justifiedAbsenceRate: 0,
      unjustifiedAbsenceRate: 0,
      recordedDays: 0,
      presentDays: 0,
      justifiedAbsenceDays: 0,
      unjustifiedAbsenceDays: 0,
    ),
    evolution: const AttendanceEvolution(
      granularity: AttendanceEvolutionGranularity.month,
      currentBucketIndex: 0,
    ),
  );

  setUpAll(() => registerFallbackValue(StatsPeriod.year));

  setUp(() {
    mockRepository = MockAttendanceStatsRepository();
    usecase = GetAttendanceOverviewUseCase(mockRepository);
  });

  void stubRepo() {
    when(
      () => mockRepository.getAttendanceOverview(
        period: any(named: 'period'),
        month: any(named: 'month'),
        week: any(named: 'week'),
      ),
    ).thenAnswer((_) async => Right(tOverview));
  }

  // Pas de garde-fou : l'endpoint overview accepte des ancres absentes (le
  // backend retombe sur la periode courante). Le usecase delegue toujours.

  test(
    'period par defaut (year) -> delegue une seule fois, retourne Right',
    () async {
      stubRepo();

      final result = await usecase();

      expect(result, Right<Failure, AttendanceOverview>(tOverview));
      verify(
        () => mockRepository.getAttendanceOverview(
          period: StatsPeriod.year,
          month: null,
          week: null,
        ),
      ).called(1);
    },
  );

  test(
    'period=month avec month valide -> delegue avec les bons arguments',
    () async {
      stubRepo();

      final result = await usecase(period: StatsPeriod.month, month: '2026-02');

      expect(result, Right<Failure, AttendanceOverview>(tOverview));
      verify(
        () => mockRepository.getAttendanceOverview(
          period: StatsPeriod.month,
          month: '2026-02',
          week: null,
        ),
      ).called(1);
    },
  );

  test(
    'period=week avec week valide -> delegue avec les bons arguments',
    () async {
      stubRepo();

      final result = await usecase(period: StatsPeriod.week, week: '2026-W05');

      expect(result, Right<Failure, AttendanceOverview>(tOverview));
      verify(
        () => mockRepository.getAttendanceOverview(
          period: StatsPeriod.week,
          month: null,
          week: '2026-W05',
        ),
      ).called(1);
    },
  );

  test(
    'period=month SANS month -> delegue avec month null (pas de garde-fou)',
    () async {
      stubRepo();

      final result = await usecase(period: StatsPeriod.month);

      expect(result, Right<Failure, AttendanceOverview>(tOverview));
      verify(
        () => mockRepository.getAttendanceOverview(
          period: StatsPeriod.month,
          month: null,
          week: null,
        ),
      ).called(1);
    },
  );

  test(
    'period=week SANS week -> delegue avec week null (pas de garde-fou)',
    () async {
      stubRepo();

      final result = await usecase(period: StatsPeriod.week);

      expect(result, Right<Failure, AttendanceOverview>(tOverview));
      verify(
        () => mockRepository.getAttendanceOverview(
          period: StatsPeriod.week,
          month: null,
          week: null,
        ),
      ).called(1);
    },
  );

  test(
    'ancres parasites (month+week sur period=year) -> transmises telles quelles',
    () async {
      stubRepo();

      final result = await usecase(
        period: StatsPeriod.year,
        month: '2026-02',
        week: '2026-W05',
      );

      expect(result, Right<Failure, AttendanceOverview>(tOverview));
      verify(
        () => mockRepository.getAttendanceOverview(
          period: StatsPeriod.year,
          month: '2026-02',
          week: '2026-W05',
        ),
      ).called(1);
    },
  );

  test(
    'le repository renvoie Left(ServerFailure) -> propage tel quel',
    () async {
      when(
        () => mockRepository.getAttendanceOverview(
          period: any(named: 'period'),
          month: any(named: 'month'),
          week: any(named: 'week'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await usecase();

      expect(result, const Left<Failure, AttendanceOverview>(ServerFailure()));
    },
  );
}

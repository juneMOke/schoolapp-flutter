import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_stats_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';

class MockGetEnrollmentStatsUseCase extends Mock
    implements GetEnrollmentStatsUseCase {}

final tStats = EnrollmentStats(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'year',
    periodStart: DateTime.utc(2025, 9, 1),
    periodEnd: DateTime.utc(2026, 6, 30),
    generatedAt: DateTime.utc(2026, 5, 23, 8),
  ),
  kpis: const EnrollmentKpis(
    totalEnrollments: KpiValue(value: 120),
    firstEnrollments: KpiValue(value: 90, percentOfTotal: 75),
    reEnrollments: KpiValue(value: 20, percentOfTotal: 17),
    preEnrollments: KpiValue(value: 10, percentOfTotal: 8),
    inProgress: KpiValue(value: 5),
  ),
  evolution: const EnrollmentEvolution(
    granularity: EvolutionGranularity.month,
    currentBucketIndex: 8,
    buckets: <EvolutionBucket>[
      EvolutionBucket(key: '2025-09', value: 12, isCurrent: false),
      EvolutionBucket(key: '2026-05', value: 18, isCurrent: true),
    ],
  ),
  distributionByCycle: const CycleDistribution(
    cycles: <CycleStat>[
      CycleStat(
        code: 'PRIMARY',
        total: 70,
        levels: <LevelStat>[LevelStat(code: 'P1', value: 30)],
      ),
    ],
  ),
  distributionByGender: const GenderDistribution(
    total: 120,
    segments: <GenderSegment>[
      GenderSegment(code: GenderSegmentCode.male, value: 62, percent: 52),
    ],
  ),
);

void main() {
  late MockGetEnrollmentStatsUseCase mockGetEnrollmentStatsUseCase;

  setUp(() {
    mockGetEnrollmentStatsUseCase = MockGetEnrollmentStatsUseCase();
  });

  EnrollmentStatsBloc buildBloc() => EnrollmentStatsBloc(
    getEnrollmentStatsUseCase: mockGetEnrollmentStatsUseCase,
  );

  group('EnrollmentStatsRequested', () {
    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'emits [loading, success] when use case succeeds',
      setUp: () {
        when(
          () => mockGetEnrollmentStatsUseCase(
            period: EnrollmentStatsPeriod.year,
            month: null,
            week: null,
          ),
        ).thenAnswer((_) async => Right(tStats));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const EnrollmentStatsRequested()),
      expect: () => [
        isA<EnrollmentStatsState>()
            .having(
              (state) => state.status,
              'status',
              EnrollmentStatsStatus.loading,
            )
            .having(
              (state) => state.errorType,
              'errorType',
              EnrollmentStatsErrorType.none,
            ),
        isA<EnrollmentStatsState>()
            .having(
              (state) => state.status,
              'status',
              EnrollmentStatsStatus.success,
            )
            .having((state) => state.stats, 'stats', tStats)
            .having(
              (state) => state.errorType,
              'errorType',
              EnrollmentStatsErrorType.none,
            ),
      ],
      verify: (_) {
        verify(
          () => mockGetEnrollmentStatsUseCase(
            period: EnrollmentStatsPeriod.year,
            month: null,
            week: null,
          ),
        ).called(1);
      },
    );

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'emits [loading, error] with mapped network error type',
      setUp: () {
        when(
          () => mockGetEnrollmentStatsUseCase(
            period: EnrollmentStatsPeriod.month,
            month: '2026-05',
            week: null,
          ),
        ).thenAnswer(
          (_) async => const Left(NetworkFailure('Network error occurred')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentStatsRequested(
          period: EnrollmentStatsPeriod.month,
          month: '2026-05',
        ),
      ),
      expect: () => [
        isA<EnrollmentStatsState>().having(
          (state) => state.status,
          'status',
          EnrollmentStatsStatus.loading,
        ),
        isA<EnrollmentStatsState>()
            .having(
              (state) => state.status,
              'status',
              EnrollmentStatsStatus.error,
            )
            .having(
              (state) => state.errorType,
              'errorType',
              EnrollmentStatsErrorType.network,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              'Verifiez votre connexion internet',
            ),
      ],
    );
  });
}
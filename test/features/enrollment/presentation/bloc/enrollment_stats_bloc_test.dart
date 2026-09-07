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
  headcount: const GenderDistribution(total: 0, segments: <GenderSegment>[]),
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
      EvolutionBucket(
        key: '2025-09',
        shortLabel: '2025-09',
        longLabel: '2025-09',
        value: 12,
        isCurrent: false,
      ),
      EvolutionBucket(
        key: '2026-05',
        shortLabel: '2026-05',
        longLabel: '2026-05',
        value: 18,
        isCurrent: true,
      ),
    ],
  ),
  distributionByCycle: const CycleDistribution(
    cycles: <CycleStat>[
      CycleStat(
        code: 'PRIMARY',
        label: 'PRIMARY',
        total: 70,
        levels: <LevelStat>[
          LevelStat(
            id: 'p1-id',
            code: 'P1',
            label: 'P1',
            cycle: 'PRIMARY',
            value: 30,
          ),
        ],
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
            window: const EnrollmentStatsWindow.year(),
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
            .having((state) => state.failure, 'failure', isNull),
        isA<EnrollmentStatsState>()
            .having(
              (state) => state.status,
              'status',
              EnrollmentStatsStatus.success,
            )
            .having((state) => state.stats, 'stats', tStats)
            .having((state) => state.failure, 'failure', isNull),
      ],
      verify: (_) {
        verify(
          () => mockGetEnrollmentStatsUseCase(
            window: const EnrollmentStatsWindow.year(),
          ),
        ).called(1);
      },
    );

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'emits [loading, error] with mapped network error type',
      setUp: () {
        when(
          () => mockGetEnrollmentStatsUseCase(
            window: const EnrollmentStatsWindow.month(),
          ),
        ).thenAnswer(
          (_) async => const Left(NetworkFailure('Network error occurred')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentStatsRequested(window: EnrollmentStatsWindow.month()),
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
            .having((state) => state.failure, 'failure', isA<NetworkFailure>())
            // L'échec emporte les données avec lui : rien de périmé ne survit
            // sous un écran en erreur.
            .having((state) => state.stats, 'stats', isNull),
      ],
    );
  });
}

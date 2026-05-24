import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_stats_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_stats_bloc.dart';

class MockGetFinanceStatsUseCase extends Mock implements GetFinanceStatsUseCase {}

final tStats = FinanceStats(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'year',
    periodStart: DateTime.utc(2025, 9, 1),
    periodEnd: DateTime.utc(2026, 6, 30),
    generatedAt: DateTime.utc(2026, 5, 23, 8),
  ),
  kpis: const FinanceKpis(
    collected: 300000,
    expected: 400000,
    outstanding: 100000,
    collectionRate: 75,
  ),
  evolution: const FinanceEvolution(
    granularity: FinanceEvolutionGranularity.month,
    currentBucketIndex: 8,
    buckets: <FinanceEvolutionBucket>[
      FinanceEvolutionBucket(key: '2025-09', value: 12000, isCurrent: false),
      FinanceEvolutionBucket(key: '2026-05', value: 18000, isCurrent: true),
    ],
  ),
  distributionByFeeType: const FeeTypeDistribution(
    items: <FeeTypeItem>[
      FeeTypeItem(
        code: 'TUITION',
        collected: 200000,
        expected: 240000,
        collectionRate: 83,
      ),
    ],
  ),
);

void main() {
  late MockGetFinanceStatsUseCase mockGetFinanceStatsUseCase;

  setUp(() {
    mockGetFinanceStatsUseCase = MockGetFinanceStatsUseCase();
  });

  FinanceStatsBloc buildBloc() =>
      FinanceStatsBloc(getFinanceStatsUseCase: mockGetFinanceStatsUseCase);

  group('FinanceStatsRequested', () {
    blocTest<FinanceStatsBloc, FinanceStatsState>(
      'emits [loading, success] when use case succeeds',
      setUp: () {
        when(
          () => mockGetFinanceStatsUseCase(
            period: FinanceStatsPeriod.year,
            month: null,
            week: null,
          ),
        ).thenAnswer((_) async => Right(tStats));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FinanceStatsRequested()),
      expect: () => [
        isA<FinanceStatsState>()
            .having((state) => state.status, 'status', FinanceStatsStatus.loading)
            .having(
              (state) => state.errorType,
              'errorType',
              FinanceStatsErrorType.none,
            ),
        isA<FinanceStatsState>()
            .having((state) => state.status, 'status', FinanceStatsStatus.success)
            .having((state) => state.stats, 'stats', tStats),
      ],
    );

    blocTest<FinanceStatsBloc, FinanceStatsState>(
      'emits [loading, error] with mapped validation error type',
      setUp: () {
        when(
          () => mockGetFinanceStatsUseCase(
            period: FinanceStatsPeriod.month,
            month: '2026-05',
            week: null,
          ),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure('Invalid request data')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FinanceStatsRequested(
          period: FinanceStatsPeriod.month,
          month: '2026-05',
        ),
      ),
      expect: () => [
        isA<FinanceStatsState>().having(
          (state) => state.status,
          'status',
          FinanceStatsStatus.loading,
        ),
        isA<FinanceStatsState>()
            .having((state) => state.status, 'status', FinanceStatsStatus.error)
            .having(
              (state) => state.errorType,
              'errorType',
              FinanceStatsErrorType.validation,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              'Parametres invalides',
            ),
      ],
    );
  });
}

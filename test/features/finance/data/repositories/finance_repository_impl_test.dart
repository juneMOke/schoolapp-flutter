import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/data/datasources/finance_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/models/fee_tariff_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model.dart';
import 'package:school_app_flutter/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';

class MockFinanceRemoteDataSource extends Mock
    implements FinanceRemoteDataSource {}

const tRequiredAuth = <String, dynamic>{'requiresAuth': true};

const tTariffModel = FeeTariffModel(
  id: 'tariff-1',
  label: 'Tuition',
  amount: 150000,
  currency: 'XOF',
  levelId: 'level-1',
);

final tFinanceStatsResponseModel = FinanceStatsResponseModel(
  context: StatsContextModel(
    schoolYear: '2025-2026',
    period: 'month',
    periodStart: DateTime.utc(2026, 5, 1),
    periodEnd: DateTime.utc(2026, 5, 31),
    generatedAt: DateTime.utc(2026, 5, 23, 8),
  ),
  kpis: const FinanceKpisModel(
    collected: 150000,
    expected: 200000,
    outstanding: 50000,
    collectionRate: 75,
  ),
  evolution: const FinanceEvolutionModel(
    granularity: 'week',
    currentBucketIndex: 1,
    buckets: <FinanceEvolutionBucketModel>[
      FinanceEvolutionBucketModel(
        key: '2026-W20',
        value: 50000,
        isCurrent: false,
      ),
      FinanceEvolutionBucketModel(
        key: '2026-W21',
        value: 100000,
        isCurrent: true,
      ),
    ],
  ),
  distributionByFeeType: const FeeTypeDistributionModel(
    items: <FeeTypeItemModel>[
      FeeTypeItemModel(
        code: 'TUITION',
        collected: 120000,
        expected: 150000,
        collectionRate: 80,
      ),
    ],
  ),
);

void main() {
  late MockFinanceRemoteDataSource mockRemoteDataSource;
  late FinanceRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockFinanceRemoteDataSource();
    repository = FinanceRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      requiredAuth: tRequiredAuth,
    );
  });

  group('getFeeTariffsByLevel', () {
    test('returns Right(List<FeeTariff>) when datasource succeeds', () async {
      when(
        () => mockRemoteDataSource.listTariffsByLevel(tRequiredAuth, 'level-1'),
      ).thenAnswer((_) async => const [tTariffModel]);

      final result = await repository.getFeeTariffsByLevel(levelId: 'level-1');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (tariffs) => expect(tariffs.first.id, 'tariff-1'),
      );
    });
  });

  group('getFinanceStats', () {
    test('returns Right(FinanceStats) when datasource succeeds', () async {
      when(
        () => mockRemoteDataSource.getFinanceStats(
          tRequiredAuth,
          'month',
          '2026-05',
          null,
        ),
      ).thenAnswer((_) async => tFinanceStatsResponseModel);

      final result = await repository.getFinanceStats(
        period: FinanceStatsPeriod.month,
        month: '2026-05',
      );

      result.fold((_) => fail('Expected Right but got Left'), (stats) {
        expect(stats.context.schoolYear, '2025-2026');
        expect(stats.kpis.collectionRate, 75);
        expect(stats.distributionByFeeType.items.first.code, 'TUITION');
      });

      verify(
        () => mockRemoteDataSource.getFinanceStats(
          tRequiredAuth,
          'month',
          '2026-05',
          null,
        ),
      ).called(1);
    });

    test('returns Left(Failure) when DioException carries Failure', () async {
      const failure = ValidationFailure('Invalid request data');
      when(
        () => mockRemoteDataSource.getFinanceStats(
          tRequiredAuth,
          'week',
          null,
          '2026-W21',
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.getFinanceStats(
        period: FinanceStatsPeriod.week,
        week: '2026-W21',
      );

      expect(result, const Left<Failure, FinanceStats>(failure));
    });
  });
}

DioException _dioException({Object? error}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/finance-stats'),
    error: error,
    type: DioExceptionType.unknown,
  );
}

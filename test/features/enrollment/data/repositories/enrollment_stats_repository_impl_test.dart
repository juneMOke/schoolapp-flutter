import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model.dart';
import 'package:school_app_flutter/features/enrollment/data/repositories/enrollment_stats_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';

class MockEnrollmentRemoteDataSource extends Mock
    implements EnrollmentRemoteDataSource {}

const tRequiredAuth = <String, dynamic>{'requiresAuth': true};

final tResponseModel = EnrollmentStatsResponseModel(
  headcount: const GenderDistributionModel(
    total: 120,
    segments: <GenderSegmentModel>[
      GenderSegmentModel(code: 'FEMALE', value: 62, percent: 52),
      GenderSegmentModel(code: 'MALE', value: 58, percent: 48),
    ],
  ),
  context: StatsContextModel(
    schoolYear: '2025-2026',
    period: 'year',
    periodStart: DateTime.utc(2025, 9, 1),
    periodEnd: DateTime.utc(2026, 6, 30),
    generatedAt: DateTime.utc(2026, 5, 23, 8),
  ),
  kpis: const EnrollmentKpisModel(
    totalEnrollments: KpiValueModel(value: 120),
    firstEnrollments: KpiValueModel(value: 90, percentOfTotal: 75),
    reEnrollments: KpiValueModel(value: 20, percentOfTotal: 17),
    preEnrollments: KpiValueModel(value: 10, percentOfTotal: 8),
    inProgress: KpiValueModel(value: 5),
  ),
  evolution: const EnrollmentEvolutionModel(
    granularity: 'month',
    currentBucketIndex: 8,
    buckets: <EvolutionBucketModel>[
      EvolutionBucketModel(
        key: '2025-09',
        shortLabel: '2025-09',
        longLabel: '2025-09',
        value: 12,
        isCurrent: false,
      ),
      EvolutionBucketModel(
        key: '2026-05',
        shortLabel: '2026-05',
        longLabel: '2026-05',
        value: 18,
        isCurrent: true,
      ),
    ],
  ),
  distributionByCycle: const CycleDistributionModel(
    cycles: <CycleStatModel>[
      CycleStatModel(
        code: 'PRIMARY',
        label: 'PRIMARY',
        total: 70,
        levels: <LevelStatModel>[
          LevelStatModel(
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
  distributionByGender: const GenderDistributionModel(
    total: 120,
    segments: <GenderSegmentModel>[
      GenderSegmentModel(code: 'MALE', value: 62, percent: 52),
    ],
  ),
);

void main() {
  late MockEnrollmentRemoteDataSource mockRemoteDataSource;
  late EnrollmentStatsRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockEnrollmentRemoteDataSource();
    repository = EnrollmentStatsRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      requiredAuth: tRequiredAuth,
    );
  });

  group('getEnrollmentStats', () {
    test('returns Right(EnrollmentStats) when datasource succeeds', () async {
      when(
        () => mockRemoteDataSource.getEnrollmentStats(
          tRequiredAuth,
          'year',
          null,
          null,
          null,
        ),
      ).thenAnswer((_) async => tResponseModel);

      final result = await repository.getEnrollmentStats();

      result.fold((_) => fail('Expected Right but got Left'), (stats) {
        expect(stats.context.schoolYear, '2025-2026');
        expect(stats.context.period, 'year');
        expect(stats.kpis.totalEnrollments.value, 120);
        expect(
          stats.distributionByGender.segments.first.code,
          GenderSegmentCode.male,
        );
      });

      verify(
        () => mockRemoteDataSource.getEnrollmentStats(
          tRequiredAuth,
          'year',
          null,
          null,
          null,
        ),
      ).called(1);
    });

    test('returns Left(Failure) when DioException carries Failure', () async {
      const failure = UnauthorizedFailure('Access forbidden');
      when(
        () => mockRemoteDataSource.getEnrollmentStats(
          tRequiredAuth,
          'month',
          null,
          null,
          null,
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.getEnrollmentStats(
        window: const EnrollmentStatsWindow.month(),
      );

      expect(result, const Left<Failure, EnrollmentStats>(failure));
    });

    test(
      'returns Left(NetworkFailure) when DioException has no Failure',
      () async {
        when(
          () => mockRemoteDataSource.getEnrollmentStats(
            tRequiredAuth,
            'day',
            '2026-05-21',
            null,
            null,
          ),
        ).thenThrow(_dioException(error: Exception('socket error')));

        final result = await repository.getEnrollmentStats(
          window: EnrollmentStatsWindow.day(DateTime(2026, 5, 21)),
        );

        expect(
          result,
          const Left<Failure, EnrollmentStats>(
            NetworkFailure('Network error occurred'),
          ),
        );
      },
    );
  });
}

DioException _dioException({Object? error}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/enrollment-stats'),
    error: error,
    type: DioExceptionType.unknown,
  );
}

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model.dart';
import 'package:school_app_flutter/features/enrollment/data/repositories/enrollment_stats_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';

import '../../../../test_helpers/widget_test_utils.dart';

class MockEnrollmentRemoteDataSource extends Mock
    implements EnrollmentRemoteDataSource {}

final _tStatsResponseModel = EnrollmentStatsResponseModel(
  context: StatsContextModel(
    schoolYear: '2025-2026',
    period: 'month',
    periodStart: DateTime.utc(2026, 5, 1),
    periodEnd: DateTime.utc(2026, 5, 31),
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
    granularity: 'week',
    currentBucketIndex: 2,
    buckets: <EvolutionBucketModel>[
      EvolutionBucketModel(key: '2026-W19', value: 12, isCurrent: false),
      EvolutionBucketModel(key: '2026-W20', value: 20, isCurrent: false),
      EvolutionBucketModel(key: '2026-W21', value: 18, isCurrent: true),
    ],
  ),
  distributionByCycle: const CycleDistributionModel(
    cycles: <CycleStatModel>[
      CycleStatModel(
        code: 'PRIMARY',
        total: 70,
        levels: <LevelStatModel>[
          LevelStatModel(code: 'P1', value: 30),
          LevelStatModel(code: 'P2', value: 40),
        ],
      ),
    ],
  ),
  distributionByGender: const GenderDistributionModel(
    total: 120,
    segments: <GenderSegmentModel>[
      GenderSegmentModel(code: 'MALE', value: 62, percent: 52),
      GenderSegmentModel(code: 'FEMALE', value: 58, percent: 48),
    ],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEnrollmentRemoteDataSource mockRemoteDataSource;

  setUpAll(() async {
    await installCommonTestPluginMocks();
  });

  setUp(() async {
    await configureDependencies();

    mockRemoteDataSource = MockEnrollmentRemoteDataSource();

    if (getIt.isRegistered<EnrollmentStatsRepository>()) {
      getIt.unregister<EnrollmentStatsRepository>();
    }

    getIt.registerLazySingleton<EnrollmentStatsRepository>(
      () => EnrollmentStatsRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        requiredAuth: getIt<Map<String, dynamic>>(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  tearDownAll(() async {
    await removeCommonTestPluginMocks();
  });

  group('EnrollmentStatsBloc + DI integration', () {
    test('getIt resolve EnrollmentStatsBloc en factory', () async {
      final firstBloc = getIt<EnrollmentStatsBloc>();
      final secondBloc = getIt<EnrollmentStatsBloc>();

      expect(firstBloc, isNot(same(secondBloc)));

      await firstBloc.close();
      await secondBloc.close();
    });

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'injecte le repository via getIt et emet [loading, success] avec le datasource mocke',
      setUp: () {
        when(
          () => mockRemoteDataSource.getEnrollmentStats(
            any(),
            'month',
            '2026-05',
            null,
          ),
        ).thenAnswer((_) async => _tStatsResponseModel);
      },
      build: () => getIt<EnrollmentStatsBloc>(),
      act: (bloc) => bloc.add(
        const EnrollmentStatsRequested(
          period: EnrollmentStatsPeriod.month,
          month: '2026-05',
        ),
      ),
      expect: () => [
        isA<EnrollmentStatsState>()
            .having(
              (state) => state.status,
              'status',
              EnrollmentStatsStatus.loading,
            )
            .having(
              (state) => state.selectedPeriod,
              'selectedPeriod',
              EnrollmentStatsPeriod.month,
            )
            .having((state) => state.selectedMonth, 'selectedMonth', '2026-05'),
        isA<EnrollmentStatsState>()
            .having(
              (state) => state.status,
              'status',
              EnrollmentStatsStatus.success,
            )
            .having(
              (state) => state.stats?.context.schoolYear,
              'schoolYear',
              '2025-2026',
            )
            .having(
              (state) => state.stats?.evolution.buckets.length,
              'bucketCount',
              3,
            )
            .having(
              (state) => state.errorType,
              'errorType',
              EnrollmentStatsErrorType.none,
            ),
      ],
      verify: (_) {
        final captured = verify(
          () => mockRemoteDataSource.getEnrollmentStats(
            captureAny(),
            'month',
            '2026-05',
            null,
          ),
        ).captured;

        expect(captured.first, isA<Map<String, dynamic>>());
        expect(
          captured.first as Map<String, dynamic>,
          containsPair('requiresAuth', true),
        );
      },
    );

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'propage une erreur mapped via le chainage DI complet',
      setUp: () {
        when(
          () => mockRemoteDataSource.getEnrollmentStats(
            any(),
            'week',
            null,
            '2026-W21',
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/enrollment-stats'),
            error: const UnauthorizedFailure('Access forbidden'),
            type: DioExceptionType.badResponse,
          ),
        );
      },
      build: () => getIt<EnrollmentStatsBloc>(),
      act: (bloc) => bloc.add(
        const EnrollmentStatsRequested(
          period: EnrollmentStatsPeriod.week,
          week: '2026-W21',
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
              EnrollmentStatsErrorType.unauthorized,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              'Acces non autorise',
            )
            .having((state) => state.selectedWeek, 'selectedWeek', '2026-W21'),
      ],
    );
  });
}

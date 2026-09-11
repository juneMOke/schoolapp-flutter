import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/config/app_environment.dart';
import 'package:school_app_flutter/core/config/env_config.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model.dart';
import 'package:school_app_flutter/features/enrollment/data/repositories/enrollment_stats_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';

import '../../../../core/offline/offline_full_test_db.dart';
import '../../../../test_helpers/widget_test_utils.dart';

class MockEnrollmentRemoteDataSource extends Mock
    implements EnrollmentRemoteDataSource {}

final _tStatsResponseModel = EnrollmentStatsResponseModel(
  headcount: const GenderDistributionModel(
    total: 120,
    segments: <GenderSegmentModel>[
      GenderSegmentModel(code: 'FEMALE', value: 62, percent: 52),
      GenderSegmentModel(code: 'MALE', value: 58, percent: 48),
    ],
  ),
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
      EvolutionBucketModel(
        key: '2026-W19',
        shortLabel: '2026-W19',
        longLabel: '2026-W19',
        value: 12,
        isCurrent: false,
      ),
      EvolutionBucketModel(
        key: '2026-W20',
        shortLabel: '2026-W20',
        longLabel: '2026-W20',
        value: 20,
        isCurrent: false,
      ),
      EvolutionBucketModel(
        key: '2026-W21',
        shortLabel: '2026-W21',
        longLabel: '2026-W21',
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
          LevelStatModel(
            id: 'p2-id',
            code: 'P2',
            label: 'P2',
            cycle: 'PRIMARY',
            value: 40,
          ),
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
    await configureDependencies(
      envConfig: EnvConfig.forTesting(
        appEnvironment: AppEnvironment.dev.label,
        apiBaseUrl: 'http://127.0.0.1:8080',
      ),
      offlineDatabase: await openFullOfflineDb(),
    );

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

    test('getIt resolve la liste nominative en factory', () async {
      final first = getIt<EnrollmentEntriesBloc>();
      final second = getIt<EnrollmentEntriesBloc>();

      // Le scope du tableau de bord la ferme en le quittant : un singleton
      // fermé une fois le resterait pour toutes les visites suivantes.
      expect(first, isNot(same(second)));

      await first.close();
      await second.close();
    });

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'injecte le repository via getIt et emet [loading, success] avec le datasource mocke',
      setUp: () {
        when(
          () => mockRemoteDataSource.getEnrollmentStats(
            any(),
            'month',
            null,
            null,
            null,
          ),
        ).thenAnswer((_) async => _tStatsResponseModel);
      },
      build: () => getIt<EnrollmentStatsBloc>(),
      act: (bloc) => bloc.add(
        const EnrollmentStatsRequested(window: EnrollmentStatsWindow.month()),
      ),
      expect: () => [
        isA<EnrollmentStatsState>()
            .having(
              (state) => state.status,
              'status',
              EnrollmentStatsStatus.loading,
            )
            .having(
              (state) => state.window,
              'window',
              const EnrollmentStatsWindow.month(),
            ),
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
            .having((state) => state.failure, 'failure', isNull),
      ],
      verify: (_) {
        // Le contrat : `date` n'accompagne QUE `day`, `from`/`to` QUE
        // `custom`. Une fenêtre « mois » ne pose aucune borne — les trois
        // paramètres restent absents de l'URL.
        final captured = verify(
          () => mockRemoteDataSource.getEnrollmentStats(
            captureAny(),
            'month',
            null,
            null,
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
            'custom',
            null,
            '2026-05-18',
            '2026-05-24',
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
        EnrollmentStatsRequested(
          window: EnrollmentStatsWindow.custom(
            from: DateTime(2026, 5, 18),
            to: DateTime(2026, 5, 24),
          ),
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
              (state) => state.failure,
              'failure',
              isA<UnauthorizedFailure>(),
            )
            .having((state) => state.stats, 'stats', isNull)
            .having(
              (state) => state.window.kind,
              'kind',
              EnrollmentStatsWindowKind.custom,
            ),
      ],
    );
  });
}

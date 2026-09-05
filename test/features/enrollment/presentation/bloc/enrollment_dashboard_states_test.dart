import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_stats_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';

class _MockGetEnrollmentStatsUseCase extends Mock
    implements GetEnrollmentStatsUseCase {}

/// Une charge utile minimale dont on ne fait varier que les compteurs.
EnrollmentStats _statsWith({required int total, required int pre}) =>
    EnrollmentStats(
      context: StatsContext(
        schoolYear: '2026-2027',
        period: 'year',
        periodStart: DateTime.utc(2026, 9, 1),
        periodEnd: DateTime.utc(2027, 6, 30),
        generatedAt: DateTime.utc(2026, 9, 5, 8),
      ),
      headcount: const GenderDistribution(
        total: 0,
        segments: <GenderSegment>[],
      ),
      kpis: EnrollmentKpis(
        totalEnrollments: KpiValue(value: total),
        firstEnrollments: KpiValue(value: total),
        reEnrollments: const KpiValue(value: 0),
        preEnrollments: KpiValue(value: pre),
        inProgress: const KpiValue(value: 0),
      ),
      evolution: const EnrollmentEvolution(
        granularity: EvolutionGranularity.month,
        currentBucketIndex: 0,
        buckets: <EvolutionBucket>[],
      ),
      distributionByCycle: const CycleDistribution(cycles: <CycleStat>[]),
      distributionByGender: const GenderDistribution(
        total: 0,
        segments: <GenderSegment>[],
      ),
    );

void main() {
  late _MockGetEnrollmentStatsUseCase useCase;

  setUpAll(() => registerFallbackValue(const EnrollmentStatsWindow.year()));

  setUp(() => useCase = _MockGetEnrollmentStatsUseCase());

  EnrollmentStatsBloc buildBloc() =>
      EnrollmentStatsBloc(getEnrollmentStatsUseCase: useCase);

  void stub(Either<Failure, EnrollmentStats> result) {
    when(
      () => useCase(window: any(named: 'window')),
    ).thenAnswer((_) async => result);
  }

  /// Le vide est un ÉTAT, décidé une fois dans le bloc — pas un `total == 0`
  /// que huit widgets testeraient chacun de leur côté.
  group('vide ou plein', () {
    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'aucune inscription et aucune demande en ligne : état vide',
      setUp: () => stub(Right(_statsWith(total: 0, pre: 0))),
      build: buildBloc,
      act: (bloc) => bloc.add(const EnrollmentStatsRequested()),
      skip: 1,
      expect: () => [
        isA<EnrollmentStatsState>().having(
          (s) => s.status,
          'status',
          EnrollmentStatsStatus.empty,
        ),
      ],
    );

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'des demandes en ligne en attente NE SONT PAS un vide',
      // « pre > 0 n'est pas un vide » : l'écran a quelque chose à dire et une
      // action à proposer, même sans une seule inscription validée.
      setUp: () => stub(Right(_statsWith(total: 0, pre: 4))),
      build: buildBloc,
      act: (bloc) => bloc.add(const EnrollmentStatsRequested()),
      skip: 1,
      expect: () => [
        isA<EnrollmentStatsState>().having(
          (s) => s.status,
          'status',
          EnrollmentStatsStatus.success,
        ),
      ],
    );

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'au moins une inscription : état plein',
      setUp: () => stub(Right(_statsWith(total: 1, pre: 0))),
      build: buildBloc,
      act: (bloc) => bloc.add(const EnrollmentStatsRequested()),
      skip: 1,
      expect: () => [
        isA<EnrollmentStatsState>().having(
          (s) => s.status,
          'status',
          EnrollmentStatsStatus.success,
        ),
      ],
    );
  });

  group('l\'erreur emporte les données', () {
    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'après une lecture réussie, un échec laisse `stats` à null',
      // LE test de la règle « sans données, l'effectif affiché serait un
      // mensonge ». Le `copyWith` conserve `stats` par défaut : sans le
      // `stats: null` explicite du bloc, le total d'il y a dix minutes
      // survivrait sous un écran en erreur, et il suffirait d'un widget
      // distrait pour qu'il s'affiche.
      setUp: () => stub(Right(_statsWith(total: 363, pre: 0))),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const EnrollmentStatsRequested());
        await Future<void>.delayed(Duration.zero);
        stub(const Left(NetworkFailure('coupure')));
        bloc.add(const EnrollmentStatsRefreshRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentStatsStatus.error);
        expect(
          bloc.state.stats,
          isNull,
          reason: 'les données périmées ne survivent pas à un échec',
        );
        expect(bloc.state.failure, isA<NetworkFailure>());
      },
    );

    blocTest<EnrollmentStatsBloc, EnrollmentStatsState>(
      'une lecture réussie efface l\'échec précédent',
      setUp: () => stub(const Left(ServerFailure('500'))),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const EnrollmentStatsRequested());
        await Future<void>.delayed(Duration.zero);
        stub(Right(_statsWith(total: 12, pre: 0)));
        bloc.add(const EnrollmentStatsRefreshRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentStatsStatus.success);
        expect(bloc.state.failure, isNull);
        expect(bloc.state.stats, isNotNull);
      },
    );
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_recovery_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_recovery_bloc.dart';

class MockGetFinanceRecoveryUseCase extends Mock
    implements GetFinanceRecoveryUseCase {}

final tRecovery = FinanceRecovery(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'year',
    periodStart: DateTime.utc(2025, 9, 1),
    periodEnd: DateTime.utc(2026, 8, 31),
    generatedAt: DateTime.utc(2026, 5, 23, 8),
  ),
  byCurrency: const [
    RecoveryCurrencyBlock(
      currency: 'USD',
      kpis: FinanceKpis(
        collected: 300000,
        expected: 400000,
        outstanding: 100000,
        collectionRate: 75,
      ),
      byFeeCode: <FeeTypeItem>[
        FeeTypeItem(
          code: 'TUITION',
          label: 'Minerval',
          collected: 200000,
          expected: 240000,
          outstanding: 40000,
          collectionRate: 83,
        ),
      ],
      monthlyCollected: FinanceEvolution(
        granularity: FinanceEvolutionGranularity.month,
        currentBucketIndex: 8,
        buckets: <FinanceEvolutionBucket>[
          FinanceEvolutionBucket(
            key: '2025-09',
            value: 12000,
            isCurrent: false,
          ),
          FinanceEvolutionBucket(key: '2026-05', value: 18000, isCurrent: true),
        ],
      ),
    ),
  ],
);

void main() {
  late MockGetFinanceRecoveryUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetFinanceRecoveryUseCase();
  });

  FinanceRecoveryBloc buildBloc() =>
      FinanceRecoveryBloc(getFinanceRecoveryUseCase: mockUseCase);

  group('FinanceRecoveryRequested', () {
    blocTest<FinanceRecoveryBloc, FinanceRecoveryState>(
      'émet [chargement, succès] et n’appelle le cas d’usage sans argument',
      setUp: () {
        when(() => mockUseCase()).thenAnswer((_) async => Right(tRecovery));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FinanceRecoveryRequested()),
      expect: () => [
        const FinanceRecoveryState(status: FinanceRecoveryStatus.loading),
        FinanceRecoveryState(
          status: FinanceRecoveryStatus.success,
          recovery: tRecovery,
        ),
      ],
      verify: (_) => verify(() => mockUseCase()).called(1),
    );

    blocTest<FinanceRecoveryBloc, FinanceRecoveryState>(
      'émet [chargement, erreur] en portant l’échec lui-même',
      setUp: () {
        when(
          () => mockUseCase(),
        ).thenAnswer((_) async => const Left(UnauthorizedFailure('Forbidden')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FinanceRecoveryRequested()),
      expect: () => [
        const FinanceRecoveryState(status: FinanceRecoveryStatus.loading),
        const FinanceRecoveryState(
          status: FinanceRecoveryStatus.error,
          failure: UnauthorizedFailure('Forbidden'),
        ),
      ],
    );

    /// Le bouton « Réessayer » rejoue **cet** évènement : le recouvrement n'a
    /// pas de fenêtre à mémoriser, donc pas de second évènement à écrire.
    blocTest<FinanceRecoveryBloc, FinanceRecoveryState>(
      'un second essai efface l’échec précédent',
      setUp: () {
        var call = 0;
        when(() => mockUseCase()).thenAnswer((_) async {
          call++;
          return call == 1
              ? const Left(NetworkFailure('offline'))
              : Right(tRecovery);
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FinanceRecoveryRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FinanceRecoveryRequested());
      },
      expect: () => [
        const FinanceRecoveryState(status: FinanceRecoveryStatus.loading),
        const FinanceRecoveryState(
          status: FinanceRecoveryStatus.error,
          failure: NetworkFailure('offline'),
        ),
        const FinanceRecoveryState(status: FinanceRecoveryStatus.loading),
        FinanceRecoveryState(
          status: FinanceRecoveryStatus.success,
          recovery: tRecovery,
        ),
      ],
    );

    /// Un succès qui suit un succès ne doit pas traîner l'ancien échec, et
    /// l'inverse non plus : l'état d'erreur garde la dernière lecture réussie
    /// pour que rien ne clignote pendant la reprise.
    blocTest<FinanceRecoveryBloc, FinanceRecoveryState>(
      'un échec après un succès conserve la donnée déjà lue',
      setUp: () {
        var call = 0;
        when(() => mockUseCase()).thenAnswer((_) async {
          call++;
          return call == 1
              ? Right(tRecovery)
              : const Left(ServerFailure('boom'));
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FinanceRecoveryRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FinanceRecoveryRequested());
      },
      skip: 3,
      expect: () => [
        FinanceRecoveryState(
          status: FinanceRecoveryStatus.error,
          recovery: tRecovery,
          failure: const ServerFailure('boom'),
        ),
      ],
    );
  });
}

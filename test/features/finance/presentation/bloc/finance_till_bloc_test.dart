import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_till_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';

class MockGetFinanceTillUseCase extends Mock implements GetFinanceTillUseCase {}

FinanceTill _till(String period) => FinanceTill(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: period,
    periodStart: DateTime.utc(2026, 5, 15),
    periodEnd: DateTime.utc(2026, 5, 15),
    generatedAt: DateTime.utc(2026, 5, 15, 18, 4),
  ),
  timeZone: 'Africa/Kinshasa',
  encaisse: const [
    TillCurrencyBlock(
      currency: 'USD',
      summary: TillSummary(total: 123450, fees: 100000, boutique: 23450),
      buckets: <TillBucket>[
        TillBucket(
          key: '2026-05-15',
          total: 123450,
          fees: 100000,
          boutique: 23450,
          isCurrent: true,
        ),
      ],
    ),
  ],
  impute: const [
    TillImputation(
      currency: 'USD',
      total: 100000,
      byFeeCode: <TillFeeCodeAmount>[
        TillFeeCodeAmount(code: 'TUITION', label: 'Minerval', amount: 100000),
      ],
    ),
  ],
);

void main() {
  late MockGetFinanceTillUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetFinanceTillUseCase();
  });

  FinanceTillBloc buildBloc() =>
      FinanceTillBloc(getFinanceTillUseCase: mockUseCase);

  group('FinanceTillRequested', () {
    blocTest<FinanceTillBloc, FinanceTillState>(
      'la journée est le défaut — la question de la fermeture',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.day),
        ).thenAnswer((_) async => Right(_till('day')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FinanceTillRequested()),
      expect: () => [
        const FinanceTillState(status: FinanceTillStatus.loading),
        FinanceTillState(status: FinanceTillStatus.success, till: _till('day')),
      ],
      verify: (_) =>
          verify(() => mockUseCase(period: TillPeriod.day)).called(1),
    );

    blocTest<FinanceTillBloc, FinanceTillState>(
      'le grain demandé est retenu dès le chargement, pas à l’arrivée',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.month),
        ).thenAnswer((_) async => Right(_till('month')));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceTillRequested(period: TillPeriod.month)),
      expect: () => [
        const FinanceTillState(
          status: FinanceTillStatus.loading,
          selectedPeriod: TillPeriod.month,
        ),
        FinanceTillState(
          status: FinanceTillStatus.success,
          till: _till('month'),
          selectedPeriod: TillPeriod.month,
        ),
      ],
      verify: (_) =>
          verify(() => mockUseCase(period: TillPeriod.month)).called(1),
    );

    /// Le serveur refuse en **400** une ancre qui ne correspond pas à la
    /// période — c'est cette famille-là que l'écran verra le jour où il
    /// proposera de viser une journée passée.
    blocTest<FinanceTillBloc, FinanceTillState>(
      'émet [chargement, erreur] en portant l’échec lui-même',
      setUp: () {
        when(() => mockUseCase(period: TillPeriod.week)).thenAnswer(
          (_) async => const Left(ValidationFailure('Invalid request data')),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceTillRequested(period: TillPeriod.week)),
      expect: () => [
        const FinanceTillState(
          status: FinanceTillStatus.loading,
          selectedPeriod: TillPeriod.week,
        ),
        const FinanceTillState(
          status: FinanceTillStatus.error,
          failure: ValidationFailure('Invalid request data'),
          selectedPeriod: TillPeriod.week,
        ),
      ],
    );
  });

  group('FinanceTillRefreshRequested', () {
    blocTest<FinanceTillBloc, FinanceTillState>(
      'rejoue la fenêtre retenue, jamais le défaut',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.year),
        ).thenAnswer((_) async => Right(_till('year')));
      },
      build: buildBloc,
      seed: () => const FinanceTillState(
        status: FinanceTillStatus.error,
        failure: NetworkFailure('offline'),
        selectedPeriod: TillPeriod.year,
      ),
      act: (bloc) => bloc.add(const FinanceTillRefreshRequested()),
      expect: () => [
        const FinanceTillState(
          status: FinanceTillStatus.loading,
          selectedPeriod: TillPeriod.year,
        ),
        FinanceTillState(
          status: FinanceTillStatus.success,
          till: _till('year'),
          selectedPeriod: TillPeriod.year,
        ),
      ],
      verify: (_) {
        verify(() => mockUseCase(period: TillPeriod.year)).called(1);
        verifyNever(() => mockUseCase(period: TillPeriod.day));
      },
    );
  });
}

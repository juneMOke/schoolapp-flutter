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
      summary: TillSummary(
        total: 123450,
        fees: 100000,
        boutique: 23450,
        receiptCount: 5,
        averageTicket: 24690,
      ),
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
        FinanceTillState(
          status: FinanceTillStatus.success,
          till: _till('day'),
          selectedCurrency: 'USD',
        ),
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
          selectedCurrency: 'USD',
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
          selectedCurrency: 'USD',
        ),
      ],
      verify: (_) {
        verify(() => mockUseCase(period: TillPeriod.year)).called(1);
        verifyNever(() => mockUseCase(period: TillPeriod.day));
      },
    );
  });

  group('la caisse détaillée', () {
    blocTest<FinanceTillBloc, FinanceTillState>(
      'le dollar par défaut, jamais « la plus active »',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.day),
        ).thenAnswer((_) async => Right(_twoTills()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const FinanceTillRequested()),
      verify: (bloc) {
        // Le franc pèse soixante-dix fois le dollar sur cette fenêtre. Un
        // défaut qui suivrait l'activité changerait de segment d'un jour à
        // l'autre, et le clic machinal du caissier tomberait sur l'autre
        // caisse.
        expect(bloc.state.selectedCurrency, 'USD');
        expect(bloc.state.selectedBlock?.currency, 'USD');
      },
    );

    blocTest<FinanceTillBloc, FinanceTillState>(
      'la bascule ne rappelle pas le serveur',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.day),
        ).thenAnswer((_) async => Right(_twoTills()));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FinanceTillRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FinanceTillCurrencySelected('CDF'));
      },
      verify: (bloc) {
        expect(bloc.state.selectedCurrency, 'CDF');
        expect(bloc.state.selectedBlock?.currency, 'CDF');
        // Les deux caisses arrivent dans la même réponse : rappeler le serveur
        // ferait clignoter un écran entier sur un geste qui n'a rien demandé
        // de neuf.
        verify(() => mockUseCase(period: TillPeriod.day)).called(1);
      },
    );

    blocTest<FinanceTillBloc, FinanceTillState>(
      'la caisse examinée survit au changement de fenêtre',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.day),
        ).thenAnswer((_) async => Right(_twoTills()));
        when(
          () => mockUseCase(period: TillPeriod.month),
        ).thenAnswer((_) async => Right(_twoTills(period: 'month')));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FinanceTillRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FinanceTillCurrencySelected('CDF'));
        bloc.add(const FinanceTillRequested(period: TillPeriod.month));
      },
      verify: (bloc) {
        expect(
          bloc.state.selectedCurrency,
          'CDF',
          reason:
              'changer de période ne doit pas ramener le lecteur sur une autre '
              'caisse que celle qu’il examinait',
        );
      },
    );

    blocTest<FinanceTillBloc, FinanceTillState>(
      'une devise que la réponse ne porte plus est réarbitrée',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.day),
        ).thenAnswer((_) async => Right(_twoTills()));
        // La fenêtre annuelle ne porte que le dollar : la sélection en francs
        // ne désigne plus rien et doit retomber quelque part.
        when(
          () => mockUseCase(period: TillPeriod.year),
        ).thenAnswer((_) async => Right(_till('year')));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FinanceTillRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FinanceTillCurrencySelected('CDF'));
        bloc.add(const FinanceTillRequested(period: TillPeriod.year));
      },
      verify: (bloc) => expect(bloc.state.selectedCurrency, 'USD'),
    );

    blocTest<FinanceTillBloc, FinanceTillState>(
      'une devise inconnue est ignorée, la caisse affichée ne se vide pas',
      setUp: () {
        when(
          () => mockUseCase(period: TillPeriod.day),
        ).thenAnswer((_) async => Right(_twoTills()));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FinanceTillRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FinanceTillCurrencySelected('EUR'));
      },
      verify: (bloc) => expect(bloc.state.selectedCurrency, 'USD'),
    );

    test('aucun bloc : il n’y a pas de caisse à détailler', () {
      const state = FinanceTillState(status: FinanceTillStatus.success);

      expect(state.selectedBlock, isNull);
    });
  });
}

/// Deux caisses sur la même fenêtre — **le franc y pèse bien plus lourd**.
///
/// C'est ce déséquilibre qui rend le test du défaut discriminant : un défaut
/// « la plus active » choisirait le franc.
FinanceTill _twoTills({String period = 'day'}) => FinanceTill(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: period,
    periodStart: DateTime.utc(2026, 5, 15),
    periodEnd: DateTime.utc(2026, 5, 15),
    generatedAt: DateTime.utc(2026, 5, 15, 18, 4),
  ),
  timeZone: 'Africa/Kinshasa',
  receiptsIssued: 12,
  encaisse: const [
    // L'ordre du serveur : alphabétique, donc le franc d'abord.
    TillCurrencyBlock(
      currency: 'CDF',
      summary: TillSummary(
        total: 9000000,
        fees: 9000000,
        boutique: 0,
        receiptCount: 8,
        averageTicket: 1125000,
      ),
      buckets: <TillBucket>[
        TillBucket(
          key: '2026-05-15',
          total: 9000000,
          fees: 9000000,
          boutique: 0,
          isCurrent: true,
        ),
      ],
    ),
    TillCurrencyBlock(
      currency: 'USD',
      summary: TillSummary(
        total: 123450,
        fees: 100000,
        boutique: 23450,
        receiptCount: 5,
        averageTicket: 24690,
      ),
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
  impute: const [],
);

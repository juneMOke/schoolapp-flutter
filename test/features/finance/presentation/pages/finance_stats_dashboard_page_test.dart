import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_till_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_till_receipts_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_till_receipts_report_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_report_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_period_filter.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_loading_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_rate_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockGetFinanceTillUseCase extends Mock implements GetFinanceTillUseCase {}

class MockGetTillReceiptsUseCase extends Mock
    implements GetTillReceiptsUseCase {}

class MockGetTillReceiptsReportUseCase extends Mock
    implements GetTillReceiptsReportUseCase {}

/// La ligne de fraîcheur de la caisse lit le cubit de synchro, fourni au niveau
/// de `main.dart`. Tout test qui monte l'onglet doit donc en poser un —
/// autrement `BlocProvider.of` lève, et l'échec ne ressemble en rien à ce qui
/// l'a causé.
class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// Le bandeau du taux lit cette série, fournie par le scope de la page. Comme
/// pour la synchro ci-dessus : sans elle, `BlocProvider.of` lève, et l'échec ne
/// ressemble en rien à ce qui l'a causé.
class MockExchangeRatesCubit extends MockCubit<ExchangeRatesState>
    implements ExchangeRatesCubit {}

final tTill = FinanceTill(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'day',
    periodStart: DateTime.utc(2026, 5, 15),
    periodEnd: DateTime.utc(2026, 5, 15),
    generatedAt: DateTime.utc(2026, 5, 15, 18),
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

/// La même caisse, plus une seconde devise — de quoi rendre le sélecteur.
final tTillTwoCurrencies = FinanceTill(
  context: tTill.context,
  timeZone: tTill.timeZone,
  encaisse: [
    ...tTill.encaisse,
    const TillCurrencyBlock(
      currency: 'CDF',
      summary: TillSummary(
        total: 11500000,
        fees: 11500000,
        boutique: 0,
        receiptCount: 3,
        averageTicket: 3833333,
      ),
      buckets: <TillBucket>[
        TillBucket(
          key: '2026-05-15',
          total: 11500000,
          fees: 11500000,
          boutique: 0,
          isCurrent: true,
        ),
      ],
    ),
  ],
  impute: tTill.impute,
);

/// La coquille à deux onglets.
///
/// Ce qui se vérifie ici n'est pas le rendu des deux moitiés — chacune a ses
/// propres tests — mais **quand elles se chargent**. Un tableau de bord qui
/// appellerait ses deux routes au montage paierait deux fois le délai du
/// premier chiffre, sur une liaison de guichet, pour un écran dont on ne lit
/// qu'une moitié.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(const TillWindow.day()));

  late MockGetFinanceTillUseCase mockTill;
  late MockGetTillReceiptsUseCase mockReceipts;
  late MockGetTillReceiptsReportUseCase mockReport;
  late MockSyncStatusCubit syncCubit;
  late MockExchangeRatesCubit ratesCubit;

  setUp(() {
    mockTill = MockGetFinanceTillUseCase();
    mockReceipts = MockGetTillReceiptsUseCase();
    mockReport = MockGetTillReceiptsReportUseCase();
    syncCubit = MockSyncStatusCubit();
    ratesCubit = MockExchangeRatesCubit();
    // Série vide : ces tests portent sur le pilotage des deux onglets, pas sur
    // le bandeau. Le bandeau se lit dans son propre fichier.
    const ratesState = ExchangeRatesState(loaded: true);
    when(() => ratesCubit.state).thenReturn(ratesState);
    whenListen(
      ratesCubit,
      const Stream<ExchangeRatesState>.empty(),
      initialState: ratesState,
    );
    const syncState = SyncStatusState(status: SyncStatus.synced);
    when(() => syncCubit.state).thenReturn(syncState);
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: syncState,
    );
    when(
      () => mockTill(window: any(named: 'window')),
    ).thenAnswer((_) async => Right(tTill));
    // La table nominative est un SECOND appel, sous une seconde permission. Le
    // stub la sert vide : ce que ces tests vérifient est le pilotage, pas les
    // lignes.
    when(
      () => mockReceipts(
        window: any(named: 'window'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => const Right(TillReceiptsPage.empty));
  });

  /// [settle] à `false` quand la lecture de la caisse est volontairement
  /// retenue : la page l'appelle désormais AU MONTAGE — il n'y a plus d'onglet
  /// derrière lequel attendre — et `pumpAndSettle` n'aurait rien à stabiliser.
  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<FinanceTillBloc>(
            create: (_) => FinanceTillBloc(getFinanceTillUseCase: mockTill),
          ),
          BlocProvider<FinanceTillReceiptsBloc>(
            create: (_) =>
                FinanceTillReceiptsBloc(getTillReceiptsUseCase: mockReceipts),
          ),
          // Le bouton de téléchargement du rapport vit dans la carte des
          // paiements ; sans son cubit, la carte ne se monte pas.
          BlocProvider<FinanceTillReportCubit>(
            create: (_) => FinanceTillReportCubit(
              getTillReceiptsReportUseCase: mockReport,
            ),
          ),
          BlocProvider<SyncStatusCubit>.value(value: syncCubit),
          BlocProvider<ExchangeRatesCubit>.value(value: ratesCubit),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FinanceStatsDashboardPage()),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets(
    'la page est la CAISSE : elle se charge au montage, sans onglet à choisir',
    (tester) async {
      await pumpPage(tester);

      // Le recouvrement a quitté cet écran le 2026-09-10 : il se lit sur
      // l'appareil, dans son propre module.
      expect(find.text('Recouvrement'), findsNothing);
      verify(() => mockTill(window: any(named: 'window'))).called(1);
    },
  );

  testWidgets('pendant le chargement, taux et fenêtre restent utilisables', (
    tester,
  ) async {
    // On retient la réponse en vol : c'est le seul moyen d'observer l'état de
    // chargement, que le stub traverse d'ordinaire en une frame.
    final held = Completer<Either<Failure, FinanceTill>>();
    when(
      () => mockTill(window: any(named: 'window')),
    ).thenAnswer((_) => held.future);

    final state = ExchangeRatesState(
      loaded: true,
      rates: [
        ExchangeRate(
          base: 'USD',
          quote: 'CDF',
          rateMicros: 2850000000,
          effectiveFrom: DateTime.utc(2020),
        ),
      ],
    );
    when(() => ratesCubit.state).thenReturn(state);
    whenListen(
      ratesCubit,
      const Stream<ExchangeRatesState>.empty(),
      initialState: state,
    );

    await pumpPage(tester, settle: false);

    // Le squelette de la CAISSE — trois tuiles puis un graphique puis des
    // rangées — et non celui du recouvrement, qui pose deux cartes côte à côte.
    expect(find.byType(FinanceTillLoadingView), findsOneWidget);
    // « Les contrôles restent utilisables pendant le fetch » : on doit pouvoir
    // lire à quel taux et sur quelle fenêtre on attend.
    expect(find.byType(FinanceTillRateBar), findsOneWidget);
    expect(find.byType(FinanceTillPeriodFilter), findsOneWidget);

    held.complete(Right(tTill));
    await tester.pumpAndSettle();
    expect(find.byType(FinanceTillLoadingView), findsNothing);
  });

  testWidgets('la caisse se charge une fois, au montage', (tester) async {
    await pumpPage(tester);

    verify(() => mockTill(window: any(named: 'window'))).called(1);
    // La caisse de la fenêtre est là, nommée par sa devise et sa fenêtre. Le
    // libellé dit « Caisse » et non « encaissé » : le recouvrement compte
    // l'année entière, et deux cartes homonymes se distinguent mal — même
    // depuis qu'elles vivent dans deux modules.
    expect(find.text('Caisse dollars · Aujourd\'hui'), findsOneWidget);
    // Le compteur de reçus — le seul agrégat inter-devises de l'écran.
    expect(find.text('Reçus émis'), findsOneWidget);
  });

  testWidgets('la table est demandée SANS devise — toutes les caisses', (
    tester,
  ) async {
    await pumpPage(tester);

    // L'appel de la table est à un saut de plus que celui des agrégats
    // (écouteur → bloc → cas d'usage) : il lui faut une frame supplémentaire.
    await tester.pumpAndSettle();

    // ⚠️ `currency` **n'existe plus** dans cette chaîne : la table porte tous
    // les paiements de la fenêtre, et c'est son absence qui le demande au
    // serveur. Le cas d'usage ne l'accepte plus, donc une devise réintroduite
    // ici ne compilerait pas — c'est le compilateur qui tient la règle.
    verify(
      () => mockReceipts(
        window: any(named: 'window'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).called(1);
  });

  testWidgets('basculer de caisse ne redemande pas la table', (tester) async {
    // Deux caisses, donc un sélecteur — le seul geste qui rejouait la table
    // avant qu'elle ne porte toutes les devises.
    when(
      () => mockTill(window: any(named: 'window')),
    ).thenAnswer((_) async => Right(tTillTwoCurrencies));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('FC francs (3)'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    // Un second appel rendrait exactement la même page : la table ne dépend
    // que de la fenêtre. Il ferait clignoter des lignes déjà justes et paierait
    // un aller-retour de guichet pour rien.
    verify(
      () => mockReceipts(
        window: any(named: 'window'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).called(1);
  });
}

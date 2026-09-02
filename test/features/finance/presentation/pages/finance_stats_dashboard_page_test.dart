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
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_recovery_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_till_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_recovery_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockGetFinanceRecoveryUseCase extends Mock
    implements GetFinanceRecoveryUseCase {}

class MockGetFinanceTillUseCase extends Mock implements GetFinanceTillUseCase {}

/// La ligne de fraîcheur de la caisse lit le cubit de synchro, fourni au niveau
/// de `main.dart`. Tout test qui monte l'onglet doit donc en poser un —
/// autrement `BlocProvider.of` lève, et l'échec ne ressemble en rien à ce qui
/// l'a causé.
class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

final tRecovery = FinanceRecovery(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'year',
    periodStart: DateTime.utc(2025, 9),
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
          collected: 300000,
          expected: 400000,
          outstanding: 100000,
          collectionRate: 75,
        ),
      ],
      monthlyCollected: FinanceEvolution(
        granularity: FinanceEvolutionGranularity.month,
        currentBucketIndex: 0,
        buckets: <FinanceEvolutionBucket>[
          FinanceEvolutionBucket(
            key: '2026-05',
            value: 300000,
            isCurrent: true,
          ),
        ],
      ),
    ),
  ],
);

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

/// La coquille à deux onglets.
///
/// Ce qui se vérifie ici n'est pas le rendu des deux moitiés — chacune a ses
/// propres tests — mais **quand elles se chargent**. Un tableau de bord qui
/// appellerait ses deux routes au montage paierait deux fois le délai du
/// premier chiffre, sur une liaison de guichet, pour un écran dont on ne lit
/// qu'une moitié.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(TillPeriod.day));

  late MockGetFinanceRecoveryUseCase mockRecovery;
  late MockGetFinanceTillUseCase mockTill;
  late MockSyncStatusCubit syncCubit;

  setUp(() {
    mockRecovery = MockGetFinanceRecoveryUseCase();
    mockTill = MockGetFinanceTillUseCase();
    syncCubit = MockSyncStatusCubit();
    const syncState = SyncStatusState(status: SyncStatus.synced);
    when(() => syncCubit.state).thenReturn(syncState);
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: syncState,
    );
    when(() => mockRecovery()).thenAnswer((_) async => Right(tRecovery));
    when(
      () => mockTill(period: any(named: 'period')),
    ).thenAnswer((_) async => Right(tTill));
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<FinanceRecoveryBloc>(
            create: (_) =>
                FinanceRecoveryBloc(getFinanceRecoveryUseCase: mockRecovery),
          ),
          BlocProvider<FinanceTillBloc>(
            create: (_) => FinanceTillBloc(getFinanceTillUseCase: mockTill),
          ),
          BlocProvider<SyncStatusCubit>.value(value: syncCubit),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FinanceStatsDashboardPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ouvre sur le Recouvrement et n’appelle pas la caisse', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Recouvrement'), findsOneWidget);
    expect(find.text('Caisse'), findsOneWidget);
    verify(() => mockRecovery()).called(1);
    verifyNever(() => mockTill(period: any(named: 'period')));
  });

  testWidgets('les descriptifs disent laquelle des deux questions on regarde', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text("Ce qu'il reste à encaisser cette année"), findsOneWidget);
    expect(find.text('Ce qui est entré dans le tiroir'), findsOneWidget);
  });

  testWidgets('la caisse ne se charge qu’à sa première ouverture', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('Caisse'));
    await tester.pumpAndSettle();

    verify(() => mockTill(period: any(named: 'period'))).called(1);
    // Le total du tiroir et sa moitié boutique — le seul chiffre neuf de
    // l'écran — sont là. Le libellé le NOMME « tiroir » et non « encaissé » :
    // le recouvrement affiche déjà un « Total encaissé », qui compte l'année
    // entière, et deux cartes homonymes à un onglet d'écart ne se distinguent
    // par rien.
    expect(find.text('Total du tiroir'), findsOneWidget);
    expect(find.text('Ventes boutique'), findsOneWidget);
  });

  testWidgets('les allers-retours entre onglets ne rappellent rien', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('Caisse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recouvrement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caisse'));
    await tester.pumpAndSettle();

    verify(() => mockTill(period: any(named: 'period'))).called(1);
    verify(() => mockRecovery()).called(1);
  });

  testWidgets('un échec de caisse ne touche pas le recouvrement déjà lu', (
    tester,
  ) async {
    when(
      () => mockTill(period: any(named: 'period')),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

    await pumpPage(tester);
    await tester.tap(find.text('Caisse'));
    await tester.pumpAndSettle();

    expect(find.text('Total du tiroir'), findsNothing);

    await tester.tap(find.text('Recouvrement'));
    await tester.pumpAndSettle();

    // La moitié qui a réussi est toujours là : les deux onglets ne partagent
    // ni bloc ni état.
    expect(find.text('Total du tiroir'), findsNothing);
    expect(find.text('Taux de recouvrement'), findsOneWidget);
  });
}

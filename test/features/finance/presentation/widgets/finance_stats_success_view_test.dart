import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_success_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

FinanceCurrencyBlock _block(String currency, int collected) =>
    FinanceCurrencyBlock(
      currency: currency,
      kpis: FinanceKpis(
        collected: collected,
        expected: 400000,
        outstanding: 400000 - collected,
        collectionRate: 50,
      ),
      evolution: const FinanceEvolution(
        granularity: FinanceEvolutionGranularity.month,
        currentBucketIndex: 1,
        buckets: [
          FinanceEvolutionBucket(key: '2026-04', value: 1000, isCurrent: false),
          FinanceEvolutionBucket(key: '2026-05', value: 2000, isCurrent: true),
        ],
      ),
      distributionByFeeType: const FeeTypeDistribution(
        items: [
          FeeTypeItem(
            code: 'TUITION',
            collected: 200000,
            expected: 400000,
            collectionRate: 50,
          ),
        ],
      ),
    );

FinanceStats _stats(List<FinanceCurrencyBlock> blocks) => FinanceStats(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: 'year',
    periodStart: DateTime.utc(2025, 9),
    periodEnd: DateTime.utc(2026, 6, 30),
    generatedAt: DateTime.utc(2026, 5, 23, 8),
  ),
  byCurrency: blocks,
);

Future<void> _pump(WidgetTester tester, FinanceStats stats) async {
  await tester.binding.setSurfaceSize(const Size(1280, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: FinanceStatsSuccessView(stats: stats),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Le pilotage, un bloc complet par devise.
///
/// Répéter plutôt qu'offrir un sélecteur : les blocs sont faits pour être lus
/// côte à côte, et c'est la comparaison qui a de la valeur. Un clic en cacherait
/// la moitié.
void main() {
  testWidgets('une seule devise : le tableau de bord d’avant', (tester) async {
    await _pump(tester, _stats([_block('USD', 200000)]));

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloKpiCard), findsNWidgets(4));
    // Pas d'intertitre de devise : il répéterait ce que chaque montant porte.
    expect(find.textContaining('En '), findsNothing);
  });

  testWidgets('deux devises : des indicateurs communs, des graphiques nommés', (
    tester,
  ) async {
    await _pump(tester, _stats([_block('CDF', 900000), _block('USD', 200000)]));

    expect(tester.takeException(), isNull);
    // Quatre cartes en tout, chacune portant ses deux devises. C'étaient huit
    // cartes : « Total encaissé » en francs, puis le même intitulé en dollars
    // un écran de graphiques plus bas — il fallait défiler pour lire ce qui
    // était rentré. Les montants ne sont pas additionnés pour autant : ils
    // s'empilent (cf. `finance_stats_kpi_band_test.dart`).
    expect(find.byType(EteeloKpiCard), findsNWidgets(4));
    // Les en-têtes nomment ce qui reste par devise : les graphiques.
    expect(find.text('En FC'), findsOneWidget);
    expect(find.text(r'En $'), findsOneWidget);
  });

  testWidgets('l’ordre des blocs est celui du serveur', (tester) async {
    await _pump(tester, _stats([_block('CDF', 900000), _block('USD', 200000)]));

    final headings = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((d) => d.startsWith('En '))
        .toList();
    expect(headings, ['En FC', r'En $']);
  });

  testWidgets('aucun mouvement : un état VIDE, pas un zéro', (tester) async {
    // Un zéro devrait être libellé dans une unité que personne n'a choisie.
    await _pump(tester, _stats(const []));

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloEmptyResult), findsOneWidget);
    expect(find.byType(EteeloKpiCard), findsNothing);
    expect(find.textContaining('0,00'), findsNothing);
  });

  testWidgets('les montants portent leur devise, jamais un nombre nu', (
    tester,
  ) async {
    await _pump(tester, _stats([_block('CDF', 900000)]));

    // Le bandeau affichait quatre chiffres sans unité : justes tant qu'il n'y
    // en avait qu'une, muets dès qu'il y en a deux.
    expect(find.textContaining('FC'), findsWidgets);
  });
}

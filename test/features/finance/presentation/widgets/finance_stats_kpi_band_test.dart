import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_kpi_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _kpis = FinanceKpis(
  collected: 1850000, // cents
  expected: 3000000,
  outstanding: 1150000,
  collectionRate: 62,
);

const _distribution = FeeTypeDistribution(
  items: [
    FeeTypeItem(
      code: 'TUITION',
      collected: 1500000,
      expected: 2500000,
      collectionRate: 60,
    ),
    FeeTypeItem(
      code: 'CANTEEN',
      collected: 350000,
      expected: 500000,
      collectionRate: 70,
    ),
  ],
);

const _emptyEvolution = FinanceEvolution(
  granularity: FinanceEvolutionGranularity.month,
  buckets: [],
  currentBucketIndex: 0,
);

const _usd = FinanceCurrencyBlock(
  currency: 'USD',
  kpis: _kpis,
  evolution: _emptyEvolution,
  distributionByFeeType: _distribution,
);

/// Deuxième devise : mêmes postes, montants propres. Le taux diffère du premier
/// pour qu'un test ne puisse pas confondre les deux lignes.
const _cdf = FinanceCurrencyBlock(
  currency: 'CDF',
  kpis: FinanceKpis(
    collected: 9000000,
    expected: 12000000,
    outstanding: 3000000,
    collectionRate: 75,
  ),
  evolution: _emptyEvolution,
  distributionByFeeType: _distribution,
);

Future<void> _pump(
  WidgetTester tester,
  double width, {
  List<FinanceCurrencyBlock> blocks = const [_usd],
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: SizedBox(
          width: width,
          child: FinanceStatsKpiBand(blocks: blocks),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'réutilise le composant DS KpiCard (4 cartes) et formate les montants',
    (tester) async {
      await _pump(tester, 900);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Même widget que le tableau de bord Inscription : 4 cartes KPI.
      expect(find.byType(EteeloKpiCard), findsNWidgets(4));
      // Le taux de recouvrement est rendu en pourcentage.
      expect(find.text('62%'), findsOneWidget);
      // Montant formaté en devise (jamais la valeur brute en cents), et il
      // porte enfin son unité : les KPI s'affichaient en nombre NU, justes tant
      // qu'il n'y avait qu'une devise, muets dès qu'il y en a deux.
      expect(find.textContaining('18'), findsWidgets); // 18 500,00 …
      expect(find.text('1850000'), findsNothing);
      expect(find.textContaining(r'$'), findsWidgets);
    },
  );

  testWidgets(
    'responsivité partagée : aucun débordement de l\'étroit au large',
    (tester) async {
      for (final width in [320.0, 600.0, 1280.0]) {
        await _pump(tester, width);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'débordement à ${width}dp',
        );
        expect(find.byType(EteeloKpiCard), findsNWidgets(4));
      }
    },
  );

  testWidgets('deux devises : les deux montants sur la MÊME carte', (
    tester,
  ) async {
    await _pump(tester, 900, blocks: const [_cdf, _usd]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Toujours quatre cartes : ce sont les LIGNES qui doublent, pas les
    // indicateurs. Huit cartes, c'est le tableau de bord d'avant — deux blocs
    // homonymes séparés par un écran de graphiques.
    expect(find.byType(EteeloKpiCard), findsNWidgets(4));

    // 90 000 FC et 18 500,00 $ tiennent ensemble sous « Total encaissé ».
    final encaisse = find.ancestor(
      of: find.text('Total encaissé'),
      matching: find.byType(EteeloKpiCard),
    );
    expect(
      find.descendant(of: encaisse, matching: find.textContaining('FC')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: encaisse, matching: find.textContaining(r'$')),
      findsOneWidget,
    );
  });

  testWidgets('deux devises : chaque taux dit de quelle devise il parle', (
    tester,
  ) async {
    await _pump(tester, 900, blocks: const [_cdf, _usd]);
    await tester.pumpAndSettle();

    // Un pourcentage nu ne se rattacherait à rien : deux lignes empilées sous
    // le même intitulé, et rien pour dire laquelle commente le franc.
    expect(find.text('75\u00A0% · FC'), findsOneWidget);
    expect(find.text('62\u00A0% · \$'), findsOneWidget);
    expect(find.text('62%'), findsNothing);
  });

  testWidgets('deux devises : les lignes se correspondent d\'une carte à '
      'l\'autre', (tester) async {
    // Blocs donnés dans l'ordre INVERSE du tri par code (USD avant CDF) : c'est
    // le cas où un rangement local des montants, différent de celui des taux,
    // ferait lire « 62 % » sous le montant en francs.
    await _pump(tester, 900, blocks: const [_usd, _cdf]);
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<EteeloKpiCard>(find.byType(EteeloKpiCard))
        .toList();
    final encaisse = cards.first.data.displayValues;
    final taux = cards.last.data.displayValues;

    expect(encaisse.first, contains(r'$'));
    expect(taux.first, contains(r'$'));
    expect(encaisse.last, contains('FC'));
    expect(taux.last, contains('FC'));
  });

  testWidgets('deux devises : plus de pastille de part du total', (
    tester,
  ) async {
    await _pump(tester, 900, blocks: const [_cdf, _usd]);
    await tester.pumpAndSettle();

    // La carte n'a qu'une pastille ; posée sur deux montants elle en
    // désignerait un sans le dire. Elle reste en mono-devise (test ci-dessus).
    expect(find.textContaining('%'), findsNWidgets(2)); // les deux taux
  });
}

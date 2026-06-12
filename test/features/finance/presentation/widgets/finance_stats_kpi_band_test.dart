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

Future<void> _pump(WidgetTester tester, double width) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: SizedBox(
          width: width,
          child: const FinanceStatsKpiBand(
            kpis: _kpis,
            distribution: _distribution,
          ),
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
      // Montant formaté en devise (jamais la valeur brute en cents).
      expect(find.textContaining('18'), findsWidgets); // 18 500,00 …
      expect(find.text('1850000'), findsNothing);
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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_balance_pill.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_kpi_strip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// Détail Facturation : Total dû / Déjà payé / Reste, chacun PAR DEVISE.
FinanceDetailKpiBand _kpiBand() => FinanceDetailKpiBand(
  hasCharges: true,
  totalDue: MoneyBag.of(const [Money(43000, 'USD')]),
  alreadyPaid: MoneyBag.of(const [Money(28000, 'USD')]),
  remaining: MoneyBag.of(const [Money(15000, 'USD')]),
);

/// Le cas que la bande ne savait pas rendre : un élève qui doit dans deux
/// unités. Les montants s'empilent dans la carte, jamais ne s'additionnent.
FinanceDetailKpiBand _biDeviseBand() => FinanceDetailKpiBand(
  hasCharges: true,
  totalDue: MoneyBag.of(const [Money(43000, 'USD'), Money(9000000, 'CDF')]),
  alreadyPaid: MoneyBag.of(const [Money(28000, 'USD')]),
  remaining: MoneyBag.of(const [Money(15000, 'USD'), Money(9000000, 'CDF')]),
);

Future<void> _pump(WidgetTester tester, Widget home) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bande KPI détail (cartes DS) se peint sans exception', (
    tester,
  ) async {
    await _pump(tester, AppPageBackground(child: _kpiBand()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Réutilise le composant DS partagé : 3 KpiCard.
    expect(find.byType(EteeloKpiCard), findsNWidgets(3));
  });

  testWidgets('Pastille de solde AppBar se peint sans exception', (
    tester,
  ) async {
    await _pump(
      tester,
      const AppPageBackground(
        appBar: StudentDetailAppBar(
          fullName: 'Kabongo Mwamba Daniel',
          eyebrow: 'Facturation · 6e A',
          firstName: 'Daniel',
          lastName: 'Kabongo',
          fallbackRoute: '/finances/facturations',
          showCloseButton: true,
          trailing: FacturationBalancePill(
            hasBalance: true,
            label: '150 USD dû',
          ),
        ),
        child: SizedBox(height: 200),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Composition page détail (AppBar+pastille, carte+KPI) sans exception',
    (tester) async {
      await _pump(
        tester,
        AppPageBackground(
          appBar: const StudentDetailAppBar(
            fullName: 'Kabongo Mwamba Daniel',
            eyebrow: 'Facturation · 6e A',
            firstName: 'Daniel',
            lastName: 'Kabongo',
            fallbackRoute: '/finances/facturations',
            showCloseButton: true,
            trailing: FacturationBalancePill(
              hasBalance: true,
              label: '150 USD dû',
            ),
          ),
          child: _kpiBand(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  // Montants longs (millions) à plusieurs largeurs : le FittedBox/garde-fou de
  // la carte DS doit empêcher tout débordement (RenderFlex overflow).
  FinanceDetailKpiBand longValueBand() => FinanceDetailKpiBand(
    hasCharges: true,
    totalDue: MoneyBag.of(const [Money(1250000000, 'CDF')]),
    alreadyPaid: MoneyBag.of(const [Money(999999900, 'CDF')]),
    remaining: MoneyBag.of(const [Money(250000100, 'CDF')]),
  );

  for (final width in const [340.0, 400.0, 700.0]) {
    testWidgets(
      'Bande KPI détail — montants longs à ${width}dp sans débordement',
      (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: Center(
              child: SizedBox(width: width, child: longValueBand()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  // Deux devises : chaque carte porte une ligne par unité. C'est le cas que la
  // bande ne savait pas rendre — elle sommait tout et étiquetait le résultat
  // avec la première devise venue.
  for (final width in const [340.0, 400.0, 700.0]) {
    testWidgets('Bande KPI détail — deux devises à ${width}dp', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(width: width, child: _biDeviseBand()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Les deux montants sont écrits, chacun entier. Aucune addition : 430,00 $
      // et 90 000 FC ne font pas « 9 043 000 » de quoi que ce soit.
      expect(find.textContaining('430,00'), findsWidgets);
      expect(find.textContaining('90'), findsWidgets);
    });
  }

  testWidgets('Bande KPI détail — sans créance, la valeur est INCONNUE', (
    tester,
  ) async {
    // Pas « 0 USD » : sans créance, on ne sait pas dans quelle unité l'élève ne
    // doit rien.
    await _pump(
      tester,
      const Scaffold(
        body: Center(
          child: SizedBox(
            width: 700,
            child: FinanceDetailKpiBand(
              hasCharges: false,
              totalDue: MoneyBag.empty,
              alreadyPaid: MoneyBag.empty,
              remaining: MoneyBag.empty,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('0,00'), findsNothing);
  });
}

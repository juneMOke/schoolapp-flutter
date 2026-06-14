import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_app_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_kpi_strip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// Détail Facturation : Total dû / Déjà payé / Reste (cents → devise).
FinanceDetailKpiBand _kpiBand() => const FinanceDetailKpiBand(
  hasCharges: true,
  totalDueCents: 43000,
  alreadyPaidCents: 28000,
  remainingCents: 15000,
  currency: 'USD',
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
        appBar: FacturationDetailAppBar(
          fullName: 'Kabongo Mwamba Daniel',
          eyebrow: 'Facturation · 6e A',
          firstName: 'Daniel',
          lastName: 'Kabongo',
          fallbackRoute: '/finances/facturations',
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
          appBar: const FacturationDetailAppBar(
            fullName: 'Kabongo Mwamba Daniel',
            eyebrow: 'Facturation · 6e A',
            firstName: 'Daniel',
            lastName: 'Kabongo',
            fallbackRoute: '/finances/facturations',
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
  FinanceDetailKpiBand longValueBand() => const FinanceDetailKpiBand(
    hasCharges: true,
    totalDueCents: 1250000000,
    alreadyPaidCents: 999999900,
    remainingCents: 250000100,
    currency: 'CDF',
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
}

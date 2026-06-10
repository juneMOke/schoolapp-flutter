import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_app_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_kpi_strip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

List<FinanceDetailKpiItem> _kpiItems() => const [
  FinanceDetailKpiItem(
    label: 'Total attendu',
    value: '430',
    suffix: 'USD',
    topAccentColor: Color(0xFF1B4D6B),
  ),
  FinanceDetailKpiItem(
    label: 'Déjà payé',
    value: '280',
    suffix: 'USD',
    topAccentColor: Color(0xFF3D6B4A),
  ),
  FinanceDetailKpiItem(
    label: 'Solde restant',
    value: '150',
    suffix: 'USD',
    topAccentColor: Color(0xFFC0392B),
  ),
];

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

  testWidgets('KPI strip décoré (liseré + radius) se peint sans exception', (
    tester,
  ) async {
    await _pump(
      tester,
      AppPageBackground(child: FinanceDetailKpiStrip(items: _kpiItems())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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
          child: FinanceDetailKpiStrip(items: _kpiItems()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  // Montants longs (millions) à plusieurs largeurs : le FittedBox/seuil de
  // bascule doit empêcher tout débordement (RenderFlex overflow).
  List<FinanceDetailKpiItem> longValueItems() => const [
    FinanceDetailKpiItem(
      label: 'Total attendu',
      value: '12 500 000',
      suffix: 'CDF',
      topAccentColor: Color(0xFF1B4D6B),
    ),
    FinanceDetailKpiItem(
      label: 'Déjà payé',
      value: '9 999 999',
      suffix: 'CDF',
      topAccentColor: Color(0xFF3D6B4A),
    ),
    FinanceDetailKpiItem(
      label: 'Solde restant',
      value: '2 500 001',
      suffix: 'CDF',
      topAccentColor: Color(0xFFC0392B),
    ),
  ];

  for (final width in const [340.0, 400.0, 700.0]) {
    testWidgets('KPI strip — montants longs à ${width}dp sans débordement', (
      tester,
    ) async {
      await _pump(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: FinanceDetailKpiStrip(items: longValueItems()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

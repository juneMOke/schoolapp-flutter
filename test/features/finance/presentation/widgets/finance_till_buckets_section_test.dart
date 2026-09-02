import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_buckets_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

List<TillBucket> _month() => [
  for (var day = 1; day <= 31; day++)
    TillBucket(
      key: '2026-05-${day.toString().padLeft(2, '0')}',
      total: day % 7 == 0 ? 0 : 40000 + day * 1000,
      fees: day % 7 == 0 ? 0 : 40000 + day * 1000,
      boutique: 0,
      isCurrent: day == 15,
    ),
];

List<TillBucket> _year() => [
  for (var month = 9; month <= 12; month++)
    TillBucket(
      key: '2025-${month.toString().padLeft(2, '0')}',
      total: month * 10000,
      fees: month * 10000,
      boutique: 0,
      isCurrent: false,
    ),
];

/// L'axe le plus chargé que l'écran ait à dessiner.
///
/// `CycleBarChart` a été taillé pour douze compartiments : barre fixée à
/// 20 px, aucun défilement, un libellé sous chacune. Un mois de trente-et-un
/// jours en demande presque trois fois plus, et c'est la seule période où la
/// question se pose.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    List<TillBucket> buckets, {
    Size size = const Size(1280, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FinanceTillBucketsSection(buckets: buckets),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('un mois de 31 jours tient sur une tablette en paysage', (
    tester,
  ) async {
    await pump(tester, _month());

    expect(tester.takeException(), isNull);
    expect(find.byType(CycleBarChart), findsOneWidget);
  });

  testWidgets('au-delà de douze barres, les libellés pivotent', (tester) async {
    await pump(tester, _month());

    final chart = tester.widget<CycleBarChart>(find.byType(CycleBarChart));
    expect(
      chart.verticalBottomLabels,
      isTrue,
      reason:
          'à l’horizontale, trente-et-un libellés se chevauchent ou se '
          'replient sur deux lignes',
    );
    expect(chart.items.length, 31);
  });

  testWidgets('douze barres ou moins gardent leurs libellés à plat', (
    tester,
  ) async {
    await pump(tester, _year());

    final chart = tester.widget<CycleBarChart>(find.byType(CycleBarChart));
    expect(chart.verticalBottomLabels, isFalse);
  });

  testWidgets('l’axe reste lisible sur une largeur compacte', (tester) async {
    // La section se juxtapose à la ventilation au-delà du seuil deux colonnes :
    // elle n'occupe alors que deux cinquièmes de la largeur.
    await pump(tester, _month(), size: const Size(600, 900));

    expect(tester.takeException(), isNull);
  });

  testWidgets('les libellés portent le jour, pas la clé entière', (
    tester,
  ) async {
    await pump(tester, _month());

    final chart = tester.widget<CycleBarChart>(find.byType(CycleBarChart));
    expect(chart.items.first.label, '01');
    expect(chart.items.last.label, '31');
  });

  testWidgets('l’intervalle en cours est le seul accentué', (tester) async {
    await pump(tester, _month());

    final chart = tester.widget<CycleBarChart>(find.byType(CycleBarChart));
    expect(chart.highlightedIndexes, {14});
  });

  testWidgets('un axe vide rend son état vide, pas un graphique nu', (
    tester,
  ) async {
    await pump(tester, const []);

    expect(find.byType(CycleBarChart), findsNothing);
    expect(find.text('Entrées de caisse'), findsOneWidget);
  });
}

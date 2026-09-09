import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_loading_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le squelette doit **ressembler à ce qui arrive**, sans quoi la page saute
/// sous l'œil et il ne vaut pas mieux qu'un rond qui tourne.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1280, 1200),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: FinanceTillLoadingView()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('trois tuiles, deux cartes — l’ordre de ce qui arrive', (
    tester,
  ) async {
    await pump(tester);

    // Deux caisses plus le compteur de reçus : la bande réelle d'une école
    // bi-devise.
    expect(find.byType(FinanceStatsChartCard), findsNWidgets(2));

    final cards = tester
        .widgetList<FinanceStatsChartCard>(find.byType(FinanceStatsChartCard))
        .toList();
    // Aucun titre : un squelette n'annonce pas un mot qu'il ne connaît pas.
    expect(cards.every((card) => card.title == null), isTrue);

    // Le graphique avant les rangées, et les tuiles avant les deux.
    final chartY = tester
        .getTopLeft(find.byType(FinanceStatsChartCard).first)
        .dy;
    final rowsY = tester.getTopLeft(find.byType(FinanceStatsChartCard).last).dy;
    expect(chartY, lessThan(rowsY));
  });

  testWidgets('douze barres, aux hauteurs de la maquette', (tester) async {
    await pump(tester);

    final heights = tester
        .widgetList<EteeloSkeletonBox>(find.byType(EteeloSkeletonBox))
        .map((box) => box.height)
        .toList();

    // 190 × les douze fractions de la spec.
    const expected = [
      79.8,
      110.2,
      57.0,
      140.6,
      98.8,
      167.2,
      121.6,
      87.4,
      133.0,
      68.4,
      114.0,
      152.0,
    ];
    for (final height in expected) {
      expect(
        heights.where((h) => (h - height).abs() < 0.01),
        isNotEmpty,
        reason: 'la barre de $height dp manque',
      );
    }
  });

  testWidgets('quatre rangées, largeurs dégressives', (tester) async {
    await pump(tester);

    final rows = tester
        .widgetList<EteeloSkeletonBox>(find.byType(EteeloSkeletonBox))
        .where((box) => box.height == 14 && box.width != null)
        .map((box) => box.width!)
        .toList();

    // Le titre de chaque carte est aussi une barre de 14 : on ne garde que les
    // quatre rangées, qui sont les seules à dépendre de la largeur.
    final wide = rows.where((w) => w != 180).toList();
    expect(wide.length, 4);
    for (var i = 1; i < wide.length; i++) {
      expect(
        wide[i],
        lessThan(wide[i - 1]),
        reason: 'les rangées vont du plus large au plus étroit',
      );
    }
  });

  testWidgets('aucune teinte de devise avant de la connaître', (tester) async {
    await pump(tester);

    final borders = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.border)
        .whereType<Border>()
        .where((b) => b.top.width == 3)
        .toList();

    expect(borders.length, 3);
    // Annoncer « dollars » avant de savoir serait affirmer ce qu'on ignore, et
    // la couleur changerait sous l'œil si l'ordre arrivait autrement.
    for (final border in borders) {
      expect(border.top.color, AppColors.border);
    }
  });
}

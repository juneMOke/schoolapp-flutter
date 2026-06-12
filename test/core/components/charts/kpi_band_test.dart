import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

void main() {
  List<EteeloKpiCardData> buildCards(int n) => [
    for (var i = 0; i < n; i++)
      EteeloKpiCardData(
        label: 'KPI$i',
        value: i * 10,
        accent: AppColors.enrollmentStatsAccent,
        accentSoft: AppColors.enrollmentStatsAccentSoft,
        icon: Icons.people,
      ),
  ];

  testWidgets('KpiBand rend tous les labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EteeloKpiBand(cards: buildCards(2))),
      ),
    );

    expect(find.text('KPI0'), findsOneWidget);
    expect(find.text('KPI1'), findsOneWidget);
  });

  testWidgets(
    'Mobile étroit (360) : wrap, pas de scroll horizontal, tout visible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: EteeloKpiBand(cards: buildCards(5)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toutes les cartes présentes (aucune masquée derrière un défilement).
      for (var i = 0; i < 5; i++) {
        expect(find.text('KPI$i'), findsOneWidget);
      }
      expect(find.byType(EteeloKpiCard), findsNWidgets(5));
      // Grille fluide (Wrap), pas de scroll horizontal.
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);

      // Wrap sur plusieurs lignes : la 3e carte passe sous la 1re (2 colonnes).
      final firstTop = tester.getTopLeft(find.byType(EteeloKpiCard).at(0)).dy;
      final thirdTop = tester.getTopLeft(find.byType(EteeloKpiCard).at(2)).dy;
      expect(thirdTop, greaterThan(firstTop));
    },
  );

  testWidgets('Large (1100) : les 5 cartes sur une seule ligne', (
    tester,
  ) async {
    // La fenêtre de test par défaut fait 800px : on l'élargit pour que la
    // contrainte de largeur atteigne réellement 1100.
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            child: EteeloKpiBand(cards: buildCards(5)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tops = <double>{
      for (var i = 0; i < 5; i++)
        tester.getTopLeft(find.byType(EteeloKpiCard).at(i)).dy,
    };
    expect(tops.length, 1);
  });
}

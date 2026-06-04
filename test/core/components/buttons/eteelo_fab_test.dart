import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

void main() {
  group('EteeloFab', () {
    Future<void> pumpFab(
      WidgetTester tester, {
      required double width,
      required VoidCallback? onPressed,
      String label = 'Nouvelle inscription',
      String? tooltip,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Scaffold(
              floatingActionButton: EteeloFab(
                label: label,
                icon: Icons.add,
                onPressed: onPressed,
                tooltip: tooltip,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('affiche la variante etendue a partir de 600px', (
      tester,
    ) async {
      await pumpFab(tester, width: 600, onPressed: () {});

      expect(find.text('Nouvelle inscription'), findsOneWidget);
      // La hauteur 56 est bien appliquee au FAB etendu (token autoritaire).
      expect(
        tester.getSize(find.byType(FloatingActionButton)).height,
        AppDimensions.fabHeight,
      );
    });

    testWidgets('collapse en icone-seule sous 600px avec tooltip', (
      tester,
    ) async {
      await pumpFab(tester, width: 599, onPressed: () {});

      expect(find.text('Nouvelle inscription'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Nouvelle inscription'), findsOneWidget);
    });

    testWidgets('etat desactive applique les couleurs disabled', (
      tester,
    ) async {
      await pumpFab(tester, width: 390, onPressed: null);

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.onPressed, isNull);
      expect(fab.backgroundColor, AppColors.stateDisabled);
      expect(fab.foregroundColor, AppColors.textMuted);
    });

    testWidgets('etat actif applique la couleur fabBackground', (tester) async {
      await pumpFab(tester, width: 800, onPressed: () {});

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.onPressed, isNotNull);
      expect(fab.backgroundColor, AppColors.fabBackground);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/core/widgets/page_background_halos.dart';

void main() {
  group('AppPageBackground', () {
    testWidgets('forwarde le floatingActionButton au Scaffold interne', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppPageBackground(
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('style decorated empile les halos et le filigrane Kuba', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppPageBackground(child: SizedBox.shrink())),
      );

      expect(find.byType(PageBackgroundHalos), findsOneWidget);
      expect(find.byType(KubaPatternLayer), findsOneWidget);
    });

    testWidgets('style flat n\'affiche ni halos ni filigrane', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppPageBackground(
            style: AppPageBackgroundStyle.flat,
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(PageBackgroundHalos), findsNothing);
      expect(find.byType(KubaPatternLayer), findsNothing);
    });
  });

  group('EllipseGradientTransform', () {
    test('scale l\'espace du gradient autour du centre', () {
      const transform = EllipseGradientTransform(
        center: Alignment.center,
        scaleX: 2.0,
        scaleY: 1.0,
      );
      const rect = Rect.fromLTWH(0, 0, 100, 100);

      // Matrice = T(c) * S * T(-c), centre (50, 50).
      final m = transform.transform(rect)!.storage;

      expect(m[0], closeTo(2.0, 0.001)); // scaleX
      expect(m[5], closeTo(1.0, 0.001)); // scaleY
      // Translation = c * (1 - scale) : le centre reste fixe.
      expect(m[12], closeTo(-50.0, 0.001)); // 50 * (1 - 2)
      expect(m[13], closeTo(0.0, 0.001)); // 50 * (1 - 1)
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';

/// Une fiche garde sa largeur de lecture ; une liste prend la place d'un
/// grand écran.
void main() {
  Future<double> contentWidth(WidgetTester tester, double? maxWidth) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: maxWidth == null
            ? const AppPageBackground(
                child: SizedBox(
                  key: Key('c'),
                  width: double.infinity,
                  height: 1,
                ),
              )
            : AppPageBackground(
                maxWidth: maxWidth,
                child: const SizedBox(
                  key: Key('c'),
                  width: double.infinity,
                  height: 1,
                ),
              ),
      ),
    );
    return tester.getSize(find.byKey(const Key('c'))).width;
  }

  testWidgets('par défaut, la largeur de lecture d\'une fiche', (tester) async {
    expect(
      await contentWidth(tester, null),
      AppDimensions.detailContentMaxWidth,
    );
  });

  testWidgets('un écran de liste s\'élargit sur un écran de 1920', (
    tester,
  ) async {
    expect(
      await contentWidth(tester, AppDimensions.listingContentMaxWidth),
      AppDimensions.listingContentMaxWidth,
    );
  });
}

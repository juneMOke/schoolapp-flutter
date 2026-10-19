import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';

/// Une fiche garde sa largeur de lecture ; une liste prend la place d'un
/// grand écran, davantage encore à partir de 1920.
void main() {
  Future<double> contentWidth(
    WidgetTester tester,
    PageContentWidth width, {
    Size screen = const Size(1600, 1000),
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppPageBackground(
          width: width,
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
      await contentWidth(tester, PageContentWidth.reading),
      AppDimensions.detailContentMaxWidth,
    );
  });

  testWidgets('une liste s\'élargit sur un grand écran', (tester) async {
    expect(
      await contentWidth(tester, PageContentWidth.wide),
      AppDimensions.listingContentMaxWidth,
    );
  });

  testWidgets('et davantage à partir de 1920', (tester) async {
    expect(
      await contentWidth(
        tester,
        PageContentWidth.wide,
        screen: const Size(2560, 1440),
      ),
      AppDimensions.wideContentMaxWidthXL,
    );
  });

  testWidgets('une fiche reste à sa largeur de lecture en 2560', (
    tester,
  ) async {
    expect(
      await contentWidth(
        tester,
        PageContentWidth.reading,
        screen: const Size(2560, 1440),
      ),
      AppDimensions.detailContentMaxWidth,
    );
  });
}

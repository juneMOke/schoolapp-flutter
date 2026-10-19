import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';

/// Android 15 impose le bord à bord : sans la marge système, le bas d'une
/// page passait sous la barre gestuelle, et ses côtés sous l'encoche en
/// paysage.
void main() {
  const gestureBar = 24.0;
  const notch = 32.0;
  const statusBar = 40.0;
  const screen = Size(360, 740);

  Future<Rect> contentRect(
    WidgetTester tester, {
    PreferredSizeWidget? appBar,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(
      left: notch,
      top: statusBar,
      bottom: gestureBar,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppPageBackground(
          scrollable: false,
          appBar: appBar,
          child: const SizedBox.expand(key: Key('c')),
        ),
      ),
    );
    return tester.getRect(find.byKey(const Key('c')));
  }

  testWidgets('le contenu s\'écarte de la barre gestuelle et de l\'encoche', (
    tester,
  ) async {
    final rect = await contentRect(tester);

    expect(rect.bottom, screen.height - gestureBar - AppDimensions.spacingL);
    expect(rect.left, notch + AppDimensions.spacingM);
    expect(rect.top, statusBar + AppDimensions.spacingL);
  });

  testWidgets('sous une barre d\'en-tête, la barre d\'état ne compte pas deux '
      'fois', (tester) async {
    final rect = await contentRect(
      tester,
      appBar: AppBar(toolbarHeight: kToolbarHeight),
    );

    expect(rect.top, statusBar + kToolbarHeight + AppDimensions.spacingL);
  });

  testWidgets('la barre basse reste au-dessus du clavier', (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: AppPageBackground(
          scrollable: false,
          bottomNavigationBar: SizedBox(key: Key('bar'), height: 64),
          child: SizedBox.expand(key: Key('c')),
        ),
      ),
    );

    final bar = tester.getRect(find.byKey(const Key('bar')));
    expect(bar.bottom, screen.height - 300);
    expect(
      tester.getRect(find.byKey(const Key('c'))).bottom,
      lessThanOrEqualTo(bar.top),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_share_bar.dart';

/// La barre tricolore d'une ligne de la fiche individuelle : chaque segment
/// prend la hauteur de la barre et sa part de la largeur.
Finder _segments() => find.descendant(
  of: find.byType(PresenceShareBar),
  matching: find.byType(ColoredBox),
);

void main() {
  Future<void> pump(WidgetTester tester, Widget bar) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Posée comme dans une ligne : dans un Wrap, à largeur fixe.
        body: Wrap(children: [SizedBox(width: 120, child: bar)]),
      ),
    ),
  );

  testWidgets('trois segments à la hauteur de la barre, en proportion', (
    tester,
  ) async {
    await pump(
      tester,
      const PresenceShareBar(onTimePct: 50, latePct: 25, absentPct: 25),
    );

    final boxes = tester
        .widgetList<ColoredBox>(_segments())
        .map((box) => tester.getSize(find.byWidget(box)))
        .toList();
    expect(boxes, hasLength(3));
    for (final size in boxes) {
      expect(size.height, AppDimensions.presenceShareBarHeight);
    }
    expect(boxes.first.width, 60);
    expect(boxes.last.width, 30);
  });

  testWidgets('sans pointage, la piste seule, pleine', (tester) async {
    await pump(
      tester,
      const PresenceShareBar(onTimePct: 0, latePct: 0, absentPct: 0),
    );
    final size = tester.getSize(_segments());
    expect(size, const Size(120, AppDimensions.presenceShareBarHeight));
  });
}

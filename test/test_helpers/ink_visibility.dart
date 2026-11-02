import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un `InkWell` peint son survol, son appui et son focus sur le `Material`
/// ancêtre : tout fond OPAQUE posé entre les deux (un `Container` coloré
/// dans l'`InkWell`) les recouvre. Le fond d'une zone d'appui passe par
/// `Ink(decoration:)` ou `Material(color:)`, jamais par un `DecoratedBox`.
void expectInkNotCovered(WidgetTester tester, Finder inkWells) {
  final covering = <String>[];
  for (final element in inkWells.evaluate()) {
    final boxes = find.descendant(
      of: find.byWidget(element.widget),
      matching: find.byType(DecoratedBox),
    );
    for (final box in tester.widgetList<DecoratedBox>(boxes)) {
      final decoration = box.decoration;
      if (box.position == DecorationPosition.background &&
          decoration is BoxDecoration &&
          (decoration.color?.a ?? 0) == 1) {
        covering.add('${decoration.color}');
      }
    }
  }
  expect(covering, isEmpty, reason: 'fond opaque peint par-dessus l\'encre');
}

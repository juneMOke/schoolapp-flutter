import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un format de référence d'AGENTS.md §« Écran neuf », en dp.
class ReferenceFormat {
  final String name;
  final Size size;

  /// Facteur de texte du format : ×1,3 (le plafond de l'app,
  /// `AppTypography.maxTextScaleFactor`) pour le téléphone en gros texte.
  final double textScale;

  const ReferenceFormat(this.name, this.size, {this.textScale = 1});

  @override
  String toString() => textScale == 1
      ? '$name ${size.width.toInt()}×${size.height.toInt()}'
      : '$name ${size.width.toInt()}×${size.height.toInt()} texte ×$textScale';
}

/// Téléphone, 7″ et 10″ dans les deux sens, poste, grand écran — et le
/// téléphone en texte ×1,3, là où les hauteurs fixes cassent d'abord.
const kReferenceFormats = <ReferenceFormat>[
  ReferenceFormat('téléphone', Size(360, 740)),
  ReferenceFormat('téléphone', Size(360, 740), textScale: 1.3),
  ReferenceFormat('7″ portrait', Size(600, 960)),
  ReferenceFormat('7″ paysage', Size(960, 600)),
  ReferenceFormat('10″ portrait', Size(800, 1280)),
  ReferenceFormat('10″ paysage', Size(1280, 800)),
  ReferenceFormat('poste', Size(1440, 900)),
  ReferenceFormat('grand écran', Size(1920, 1080)),
];

/// Pose la fenêtre de test à [format] : `physicalSize` et
/// `devicePixelRatio`, pas `setSurfaceSize` — qui ne change pas `MediaQuery`.
void applyReferenceFormat(WidgetTester tester, ReferenceFormat format) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = format.size;
  tester.platformDispatcher.textScaleFactorTestValue = format.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Un `testWidgets` par format de référence. Un débordement (`RenderFlex
/// overflowed`) est une exception de rendu : il fait échouer le test du
/// format où il apparaît, sans assertion de plus.
void testAtReferenceFormats(
  String description,
  Future<void> Function(WidgetTester tester, ReferenceFormat format) body,
) {
  for (final format in kReferenceFormats) {
    testWidgets('$description — $format', (tester) async {
      applyReferenceFormat(tester, format);
      await body(tester, format);
      expect(tester.takeException(), isNull);
    });
  }
}

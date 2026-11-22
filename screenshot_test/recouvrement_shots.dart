// Banc de captures du Recouvrement v2 — HORS CI (dossier `screenshot_test/`,
// jamais lu par `flutter test` sans chemin explicite). Rend les écrans avec les
// vraies polices, aux largeurs de la spec, et écrit des PNG pour les comparer
// aux captures de la maquette.
//
//   flutter test screenshot_test/recouvrement_control_shots_test.dart \
//     --dart-define=SHOTS_OUT=/chemin/de/sortie
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const shotsOut = String.fromEnvironment('SHOTS_OUT', defaultValue: '/tmp');

Future<void> loadRealFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
        File(f).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  }

  await family('Inter', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/inter/Inter_18pt-$w.ttf',
  ]);
  await family('Lora', [
    for (final w in ['Regular', 'Medium', 'SemiBold'])
      'assets/fonts/lora/Lora-$w.ttf',
  ]);
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/home/junethink/Dev/flutter';
  await family('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

/// Rend [child] dans une fenêtre de [size] (dp), pleine hauteur si [fullPage],
/// et écrit `$shotsOut/$name.png`.
Future<void> shoot(
  WidgetTester tester,
  String name,
  Size size,
  Widget child, {
  double textScale = 1,
  double fullPageHeight = 0,
}) async {
  final height = fullPageHeight > 0 ? fullPageHeight : size.height;
  tester.view.physicalSize = Size(size.width, height) * 2;
  tester.view.devicePixelRatio = 2;
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(size.width, height),
          devicePixelRatio: 2,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$shotsOut/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

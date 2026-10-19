import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_screen.dart';

import '../../helpers/shell_harness.dart';

/// Le clavier virtuel ne se retire qu'une fois : relue au-dessus du `Scaffold`
/// de la coquille, sa hauteur l'était deux fois, et une 10" en paysage
/// écrasait la page à une bande dès qu'un champ prenait le focus.
void main() {
  const keyboard = 300.0;

  for (final size in const [Size(1280, 800), Size(800, 1280), Size(600, 960)]) {
    testWidgets(
      '${size.width.toInt()} dp : l\'écran perd le clavier, une fois',
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(buildShellHarness());
        await tester.pumpAndSettle();

        tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
        await tester.pumpAndSettle();

        final screen = find.byType(ShellScreen);
        expect(
          tester.getSize(screen).height,
          size.height - AppTheme.topBarHeight - keyboard,
        );
        expect(
          MediaQuery.viewInsetsOf(tester.element(screen)).bottom,
          0,
          reason: 'le Scaffold de la coquille a déjà fait place au clavier',
        );
      },
    );
  }
}

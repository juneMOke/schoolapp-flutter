import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/keyboard/shortcuts_help.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ShortcutsHelpShortcut(child: Scaffold(body: TextField())),
    ),
  );

  testWidgets('F1 ouvre l’aide, Échap la ferme', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.text('Raccourcis clavier'), findsOneWidget);
    expect(find.text('Actualiser l\'écran'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Raccourcis clavier'), findsNothing);
  });

  testWidgets('« ? » s’écrit dans un champ, sans ouvrir l’aide', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    // F1 ignore aussi le champ : une seule convention pour les deux touches.
    expect(find.text('Raccourcis clavier'), findsNothing);
  });
}

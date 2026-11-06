import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';

import '../../../test_helpers/reference_formats.dart';

// #109 : sous 600 dp, la modale passe en plein écran et son fond ne ferme
// plus au toucher (la saisie serait perdue au premier toucher du bord).
// Échap, lui, doit fermer comme sur la forme centrée.
void main() {
  Future<void> open(
    WidgetTester tester, {
    bool barrierDismissible = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showEteeloAdaptiveDialog<void>(
                  context: context,
                  barrierDismissible: barrierDismissible,
                  builder: (_) => const EteeloAdaptiveDialog(
                    maxWidth: 400,
                    child: SizedBox(height: 120, child: Text('contenu')),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('contenu'), findsOneWidget);
  }

  Future<void> escape(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }

  group('plein écran (téléphone)', () {
    testWidgets('Échap ferme la modale', (tester) async {
      setTestWindow(tester, const Size(360, 740));
      await open(tester);
      await escape(tester);
      expect(find.text('contenu'), findsNothing);
    });

    testWidgets('le fond ne ferme pas au toucher', (tester) async {
      setTestWindow(tester, const Size(360, 740));
      await open(tester);
      // Le fond est caché par la modale ; c'est la barrière elle-même qui
      // doit refuser un toucher égaré (bande système, bord d'écran).
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.dismissible, isFalse);
    });

    testWidgets('fermeture refusée par l appelant : Échap non plus', (
      tester,
    ) async {
      setTestWindow(tester, const Size(360, 740));
      await open(tester, barrierDismissible: false);
      await escape(tester);
      expect(find.text('contenu'), findsOneWidget);
    });
  });

  group('centrée (poste)', () {
    testWidgets('Échap ferme, un toucher hors modale aussi', (tester) async {
      setTestWindow(tester, kDefaultTestWindow);
      await open(tester);
      await escape(tester);
      expect(find.text('contenu'), findsNothing);

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('contenu'), findsNothing);
    });
  });
}

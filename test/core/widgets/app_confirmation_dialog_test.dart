import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';

void main() {
  Future<bool?> answerWithEnter(
    WidgetTester tester, {
    required bool isDestructive,
  }) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAppConfirmationDialog(
                context: context,
                title: 'Titre',
                message: 'Message',
                confirmLabel: 'Confirmer',
                cancelLabel: 'Annuler',
                isDestructive: isDestructive,
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('action ordinaire : Entrée confirme', (tester) async {
    expect(await answerWithEnter(tester, isDestructive: false), isTrue);
  });

  testWidgets('action destructrice : Entrée annule', (tester) async {
    expect(await answerWithEnter(tester, isDestructive: true), isFalse);
  });

  testWidgets('une Entrée maintenue ne confirme pas d’elle-même', (
    tester,
  ) async {
    var answered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            autofocus: true,
            onPressed: () async {
              await showAppConfirmationDialog(
                context: context,
                title: 'Titre',
                message: 'Message',
                confirmLabel: 'Confirmer',
                cancelLabel: 'Annuler',
              );
              answered = true;
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.pump();

    // L'appui ouvre la modale ; la répétition de la touche gardée enfoncée
    // tombe sur « Confirmer », qui a le focus.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AppConfirmationDialog), findsOneWidget);
    expect(answered, isFalse);
  });

  testWidgets('sur un écran desktop, un long message ne s’étale pas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppConfirmationDialog(
              context: context,
              title: 'Titre',
              message:
                  'Un message assez long pour tenir sur une seule ligne '
                  'de plus de mille points si rien ne borne la modale qui le '
                  'porte, ce qui le rendrait illisible sur un grand écran.',
              confirmLabel: 'Confirmer',
              cancelLabel: 'Annuler',
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(Material),
                )
                .first,
          )
          .width,
      lessThanOrEqualTo(AppDimensions.confirmationDialogMaxWidth),
    );
  });
}

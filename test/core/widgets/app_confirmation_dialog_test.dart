import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

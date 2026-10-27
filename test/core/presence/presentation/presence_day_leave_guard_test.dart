import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_leave_guard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';

/// Ce que la garde a répondu, et combien de fois elle a validé.
class _Outcome {
  bool? mayLeave;
  int validations = 0;
}

/// La garde d'un jour pointé mais pas validé : rester, partir sans valider,
/// ou valider puis partir — seulement si la validation aboutit.
void main() {
  Future<_Outcome> ask(
    WidgetTester tester, {
    bool pending = true,
    bool? validates = true,
  }) async {
    final outcome = _Outcome();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final guard = PresenceDayLeaveGuard(
                  context,
                  isPending: () => pending,
                  title: () =>
                      'Le rapport du mardi 27 octobre n\'est pas validé',
                  message: () => 'Vos pointages sont enregistrés.',
                  validate: validates == null
                      ? null
                      : () async {
                          outcome.validations++;
                          return validates;
                        },
                );
                outcome.mayLeave = await guard.mayLeave();
              },
              child: const Text('partir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('partir'));
    await tester.pumpAndSettle();
    return outcome;
  }

  testWidgets('une carte à trois actions', (tester) async {
    await ask(tester);

    expect(
      find.text('Le rapport du mardi 27 octobre n\'est pas validé'),
      findsOneWidget,
    );
    expect(find.text('Rester'), findsOneWidget);
    expect(find.text('Quitter sans valider'), findsOneWidget);
    expect(find.text('Valider et quitter'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('« Rester » garde le jour', (tester) async {
    final outcome = await ask(tester);
    await tester.tap(find.text('Rester'));
    await tester.pumpAndSettle();

    expect(outcome.mayLeave, isFalse);
    expect(outcome.validations, 0);
  });

  testWidgets('« Quitter sans valider » part sans valider', (tester) async {
    final outcome = await ask(tester);
    await tester.tap(find.text('Quitter sans valider'));
    await tester.pumpAndSettle();

    expect(outcome.mayLeave, isTrue);
    expect(outcome.validations, 0);
  });

  testWidgets('« Valider et quitter » valide, puis part', (tester) async {
    final outcome = await ask(tester);
    await tester.tap(find.text('Valider et quitter'));
    await tester.pumpAndSettle();

    expect(outcome.validations, 1);
    expect(outcome.mayLeave, isTrue);
  });

  testWidgets('une validation qui n\'aboutit pas laisse sur le jour', (
    tester,
  ) async {
    final outcome = await ask(tester, validates: false);
    await tester.tap(find.text('Valider et quitter'));
    await tester.pumpAndSettle();

    expect(outcome.validations, 1);
    expect(outcome.mayLeave, isFalse);
  });

  testWidgets('sans validation possible, pas de « Valider et quitter »', (
    tester,
  ) async {
    await ask(tester, validates: null);

    expect(find.text('Valider et quitter'), findsNothing);
    expect(find.text('Quitter sans valider'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('un jour sans attente part sans question', (tester) async {
    final outcome = await ask(tester, pending: false);

    expect(find.text('Rester'), findsNothing);
    expect(outcome.mayLeave, isTrue);
  });

  testAtReferenceFormats('la popin tient', (tester, format) async {
    await ask(tester);
    expect(find.text('Valider et quitter'), findsOneWidget);
    await _close(tester);
  });
}

/// Referme la popin : la garde ne pose qu'une question à la fois, et une
/// popin laissée ouverte la retiendrait pour le test suivant.
Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.text('Rester'));
  await tester.pumpAndSettle();
}

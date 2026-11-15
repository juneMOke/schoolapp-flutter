import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_dialog.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

typedef _Sent = ({
  bool matches,
  int shown,
  int? declared,
  String? justification,
});

void main() {
  late List<_Sent> sent;
  late List<Either<Failure, CashClosure>> answers;
  Either<Failure, CashClosure>? result;
  Completer<Either<Failure, CashClosure>>? hold;

  Future<void> open(WidgetTester tester) async {
    setTestWindow(tester, const Size(1280, 1600));
    await tester.pumpWidget(
      treasuryHost(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showClosingDialog(
              context,
              summary: cdfDay(),
              date: demoDay,
              onClose:
                  ({
                    required matches,
                    required shownExpectedInCents,
                    declaredAmountInCents,
                    justification,
                  }) async {
                    sent.add((
                      matches: matches,
                      shown: shownExpectedInCents,
                      declared: declaredAmountInCents,
                      justification: justification,
                    ));
                    final pending = hold;
                    if (pending != null) return pending.future;
                    return answers.removeAt(0);
                  },
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  setUp(() {
    sent = [];
    answers = [];
    result = null;
    hold = null;
  });

  testWidgets('pendant l envoi, ni la barrière ni Échap ne ferment la modale', (
    tester,
  ) async {
    hold = Completer();
    await open(tester);
    await tapText(tester, 'Oui, c\'est juste');
    await tester.tap(find.text('Clôturer la caisse').last);
    await tester.pump();
    await tester.tapAt(const Offset(4, 4)); // la barrière
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Clôturer Caisse CDF'), findsOne);
    hold!.complete(Right(closedWithGap));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(sent, hasLength(1));
  });

  testWidgets('la question cite le reste exact', (tester) async {
    await open(tester);
    expect(
      find.text('Avez-vous bien 3 450 000 FC dans la caisse ?'),
      findsOneWidget,
    );
  });

  testWidgets('« Oui » : le reste montré part, sans déclaré', (tester) async {
    answers = [Right(closedWithGap)];
    await open(tester);
    await tapText(tester, 'Oui, c\'est juste');
    await tapText(tester, 'Clôturer la caisse');
    expect(sent.single.matches, isTrue);
    expect(sent.single.shown, 345000000);
    expect(sent.single.declared, isNull);
    expect(result, isNotNull);
  });

  testWidgets('« Non » : montant et justification exigés, écart en direct', (
    tester,
  ) async {
    answers = [Right(closedWithGap)];
    await open(tester);
    await tapText(tester, 'Non, il y a une différence');
    await tester.enterText(find.byType(TextField).at(0), '3 445 000');
    await tester.pumpAndSettle();
    expect(find.text('Écart -5 000 FC · il manque 5 000 FC'), findsOneWidget);
    await tapText(tester, 'Erreur de rendu de monnaie');
    await tapText(tester, 'Clôturer avec cet écart');
    expect(sent.single.matches, isFalse);
    expect(sent.single.declared, 344500000);
    expect(sent.single.justification, 'Erreur de rendu de monnaie');
  });

  testWidgets('EXPECTED_CHANGED : le nouveau reste s affiche, la réponse '
      's efface, rien n est enregistré', (tester) async {
    answers = [
      const Left(
        TreasuryRefusalFailure(
          TreasuryRefusal.expectedChanged,
          details: {'expectedInCents': 347000000},
        ),
      ),
    ];
    await open(tester);
    await tapText(tester, 'Oui, c\'est juste');
    await tapText(tester, 'Clôturer la caisse');
    expect(result, isNull);
    expect(
      find.text('Avez-vous bien 3 470 000 FC dans la caisse ?'),
      findsOneWidget,
    );
    final close = tester.widget<ButtonStyleButton>(
      find
          .ancestor(
            of: find.text('Clôturer la caisse'),
            matching: find.bySubtype<ButtonStyleButton>(),
          )
          .first,
    );
    expect(close.onPressed, isNull);
  });

  testWidgets('déjà clôturée par quelqu un d autre : la modale se ferme et '
      'rend le refus, sans rejouer', (tester) async {
    answers = [
      Left(
        TreasuryRefusalFailure(
          TreasuryRefusal.cashDayAlreadyClosed,
          closure: closedWithGap,
        ),
      ),
    ];
    await open(tester);
    await tapText(tester, 'Oui, c\'est juste');
    await tapText(tester, 'Clôturer la caisse');
    expect(result!.isLeft(), isTrue);
    expect(sent, hasLength(1));
  });
}

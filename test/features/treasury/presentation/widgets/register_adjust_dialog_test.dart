import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/register_adjust_dialog.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

void main() {
  late List<(int, int, String)> sent;
  late List<Either<Failure, CashAdjustment>> answers;
  CashAdjustment? result;

  Future<void> open(WidgetTester tester) async {
    setTestWindow(tester, const Size(1280, 900));
    await tester.pumpWidget(
      treasuryHost(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showRegisterAdjustDialog(
              context,
              config: usdConfig,
              onAdjust: (shown, next, reason) async {
                sent.add((shown, next, reason));
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

  Future<void> fill(WidgetTester tester, String amount, String reason) async {
    await tester.enterText(find.byType(TextField).at(0), amount);
    await tester.enterText(find.byType(TextField).at(1), reason);
    await tester.pumpAndSettle();
  }

  setUp(() {
    sent = [];
    answers = [];
    result = null;
  });

  testWidgets('pré-rempli au montant actuel : rien à enregistrer', (
    tester,
  ) async {
    await open(tester);
    final save = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Enregistrer l\'ajustement'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('l écart s affiche signé dès que le montant change', (
    tester,
  ) async {
    await open(tester);
    await fill(tester, '4900', 'Recomptage');
    expect(find.text('Ajustement de +80,00 \$'), findsOneWidget);
  });

  testWidgets(
    'EXPECTED_CHANGED : rien n est enregistré, le nouveau montant actuel '
    's affiche, et c est lui qui repart',
    (tester) async {
      answers = [
        const Left(
          TreasuryRefusalFailure(
            TreasuryRefusal.expectedChanged,
            details: {
              'shownExpectedInCents': 482000,
              'expectedInCents': 500000,
            },
          ),
        ),
        Right(adjustment),
      ];
      await open(tester);
      await fill(tester, '4900', 'Recomptage');
      await tester.ensureVisible(find.text('Enregistrer l\'ajustement'));
      await tester.tap(find.text('Enregistrer l\'ajustement'));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(
        find.textContaining('il est passé de 4 820,00 \$ à 5 000,00 \$'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Enregistrer l\'ajustement'));
      await tester.tap(find.text('Enregistrer l\'ajustement'));
      await tester.pumpAndSettle();

      expect(sent.map((s) => s.$1), [482000, 500000]);
      expect(result, adjustment);
    },
  );

  testWidgets('une suggestion de motif remplace le texte', (tester) async {
    await open(tester);
    await fill(tester, '4900', 'abc');
    // La suggestion est sous le pli de la modale : on défile d'abord.
    await tester.ensureVisible(find.text('Apport du promoteur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apport du promoteur'));
    await tester.pumpAndSettle();
    expect(find.text('Apport du promoteur'), findsNWidgets(2));
  });
}

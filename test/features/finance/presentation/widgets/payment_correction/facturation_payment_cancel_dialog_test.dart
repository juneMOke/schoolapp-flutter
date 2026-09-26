import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/correct_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_correction_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_correction/facturation_payment_cancel_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockCorrect extends Mock implements CorrectPaymentUseCase {}

/// Le geste « Annuler » : motif obligatoire, précision pour « Autre », et un
/// résultat toujours local.
void main() {
  late _MockCorrect correct;

  setUpAll(() {
    registerFallbackValue(
      const PaymentCorrectionDraft(
        paymentId: 'x',
        reason: PaymentCorrectionReason.other,
      ),
    );
  });

  setUp(() {
    correct = _MockCorrect();
    when(() => correct(any())).thenAnswer(
      (_) async => const Right(PaymentCorrectionOutcome(correctionId: 'pc-1')),
    );
  });

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => PaymentCorrectionCubit(correct),
            child: const FacturationPaymentCancelDialog(
              paymentId: 'p-1',
              amountLabel: '150,00 \$',
              dateLabel: '25/09/2026',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  EteeloButton cta(WidgetTester tester) => tester
      .widgetList<EteeloButton>(find.byType(EteeloButton))
      .singleWhere((b) => b.label == 'Annuler le versement');

  Future<void> choose(WidgetTester tester, PaymentCorrectionReason r) async {
    final chip = find.byKey(ValueKey('payment-correction-reason-${r.code}'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
  }

  testWidgets('sans motif, rien ne part', (tester) async {
    await open(tester);

    expect(cta(tester).onPressed, isNull);
  });

  testWidgets('seuls les motifs d annulation sont proposés', (tester) async {
    await open(tester);

    expect(find.text('Double saisie'), findsOneWidget);
    expect(find.text('Mauvais montant'), findsNothing);
  });

  testWidgets('« Autre » exige une précision', (tester) async {
    await open(tester);
    await choose(tester, PaymentCorrectionReason.other);
    expect(cta(tester).onPressed, isNull);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('payment-correction-detail')),
        matching: find.byType(TextField),
      ),
      'Mauvaise élève',
    );
    await tester.pump();

    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('le geste part avec son motif, puis dit son résultat', (
    tester,
  ) async {
    await open(tester);
    await choose(tester, PaymentCorrectionReason.duplicate);

    await tester.tap(find.widgetWithText(EteeloButton, 'Annuler le versement'));
    await tester.pump();
    await tester.pump();

    final draft =
        verify(() => correct(captureAny())).captured.single
            as PaymentCorrectionDraft;
    expect(draft.paymentId, 'p-1');
    expect(draft.reason, PaymentCorrectionReason.duplicate);
    expect(draft.replacement, isNull);
    expect(draft.cashMoved, isFalse);
    expect(find.text('Versement annulé'), findsOneWidget);
  });

  // D8 : « Argent rendu » dit déjà que de l'argent a changé de main.
  testWidgets('« Argent rendu » coche la case d argent', (tester) async {
    await open(tester);
    await choose(tester, PaymentCorrectionReason.refunded);

    await tester.tap(find.widgetWithText(EteeloButton, 'Annuler le versement'));
    await tester.pump();

    final draft =
        verify(() => correct(captureAny())).captured.single
            as PaymentCorrectionDraft;
    expect(draft.cashMoved, isTrue);
  });
}

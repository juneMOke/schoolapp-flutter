import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_correction_summary.dart';
import 'package:school_app_flutter/features/finance/offline/data/mappers/local_finance_online_mappers.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

PaymentCorrectionSummary _summary(PaymentCorrectionStatus status) =>
    PaymentCorrectionSummary(status: status, reasonCode: 'DUPLICATE');

Payment _payment({
  PaymentCorrectionSummary? correction,
  String? replacesPaymentId,
  bool isCancelled = false,
}) => Payment(
  id: 'pay-1',
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  amounts: MoneyBag.of(const [Money(15000, 'USD')]),
  payerFirstName: 'Marie',
  payerLastName: 'Tshiala',
  paidAt: DateTime(2026, 9, 25),
  isCancelled: isCancelled,
  correction: correction,
  replacesPaymentId: replacesPaymentId,
);

void main() {
  group('gestes offerts (spec §03)', () {
    test('sans droit d annuler, aucun geste', () {
      final g = facturationCorrectionGestures(
        outOfForce: false,
        canCancel: false,
        canWrite: true,
      );
      expect((g.cancel, g.correct), (false, false));
    });

    test('annuler sans pouvoir encaisser : pas de « Corriger »', () {
      final g = facturationCorrectionGestures(
        outOfForce: false,
        canCancel: true,
        canWrite: false,
      );
      expect((g.cancel, g.correct), (true, false));
    });

    test('un versement qui ne compte plus ne se corrige pas', () {
      final g = facturationCorrectionGestures(
        outOfForce: true,
        canCancel: true,
        canWrite: true,
      );
      expect((g.cancel, g.correct), (false, false));
    });
  });

  group('état d un versement visé par une correction', () {
    test('en attente : hors des soldes, annulation à synchroniser', () {
      final p = _payment(correction: _summary(PaymentCorrectionStatus.pending));
      expect(p.isOutOfForce, isTrue);
      expect(p.isCancellationPending, isTrue);
    });

    // R3 : un refus n'a rien changé côté serveur.
    test('refusée : le versement compte de nouveau', () {
      final p = _payment(
        correction: _summary(PaymentCorrectionStatus.rejected),
      );
      expect(p.isOutOfForce, isFalse);
      expect(p.isCorrectable, isTrue);
    });

    test('le mapper porte la correction jusqu à l écran', () {
      const local = LocalPayment(
        id: 'pay-1',
        clientUuid: 'pay-1',
        studentId: 'stu-1',
        method: PaymentMethod.cash,
        paidAt: '2026-09-25T12:11:41Z',
        syncState: SyncState.synced,
        replacesPaymentId: 'pay-0',
        correction: LocalPaymentCorrection(
          id: 'pc-1',
          status: PaymentCorrectionStatus.localOnly,
          reasonCode: 'WRONG_AMOUNT',
        ),
      );

      final payment = local.toOnlineEntity();

      expect(payment.replacesPaymentId, 'pay-0');
      expect(payment.correction?.status, PaymentCorrectionStatus.localOnly);
      expect(payment.isOutOfForce, isTrue);
    });
  });

  group('ligne de versement', () {
    Future<void> pump(WidgetTester tester, Payment payment) =>
        tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppPageBackground(
              child: FacturationPaymentLine(payment: payment, onTap: () {}),
            ),
          ),
        );

    TextDecoration? amountDecoration(WidgetTester tester) =>
        tester.widget<Text>(find.textContaining('+ ')).style?.decoration;

    testWidgets('annulé sur la tablette : barré, « à synchroniser »', (
      tester,
    ) async {
      await pump(
        tester,
        _payment(correction: _summary(PaymentCorrectionStatus.pending)),
      );

      expect(find.text('Annulé · à synchroniser'), findsOneWidget);
      expect(amountDecoration(tester), TextDecoration.lineThrough);
    });

    testWidgets('correction refusée : compte, et le dit', (tester) async {
      await pump(
        tester,
        _payment(correction: _summary(PaymentCorrectionStatus.rejected)),
      );

      expect(find.text('Correction refusée'), findsOneWidget);
      expect(amountDecoration(tester), isNot(TextDecoration.lineThrough));
    });

    testWidgets('le remplaçant dit d où il vient', (tester) async {
      await pump(tester, _payment(replacesPaymentId: 'pay-0'));

      expect(find.text('Remplace un versement'), findsOneWidget);
    });
  });
}

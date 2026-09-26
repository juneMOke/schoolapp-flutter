import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_origin.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_correction_context.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_collect_form_model.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_payment_correction_reads.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_rate_board.dart';

StudentCharge _charge(
  String id, {
  int expected = 4800,
  int paid = 0,
  int pending = 0,
  StudentChargeStatus status = StudentChargeStatus.due,
}) => StudentCharge(
  id: id,
  studentId: 's-1',
  academicYearId: 'ay-1',
  schoolLevelId: 'lvl-1',
  schoolLevelGroupId: 'grp-1',
  feeTariffId: 'tar-$id',
  feeTariffCode: id,
  feeCode: 'MINERVAL',
  label: 'Minerval $id',
  expectedAmountInCents: expected.toDouble(),
  amountPaidInCents: paid.toDouble(),
  amountPaidPendingInCents: pending.toDouble(),
  currency: 'USD',
  status: status,
);

/// Le cas Gloredi : 48 + 48 + 48 + 6 $ saisis, 50 $ reçus.
FacturationPaymentCorrectionContext _gloredi() =>
    FacturationPaymentCorrectionContext(
      origin: const PaymentCorrectionOrigin(
        paymentId: 'p-1',
        studentId: 's-1',
        paidAt: '2026-09-25T12:11:41Z',
        allocations: [
          PaymentCorrectionOriginAllocation(
            studentChargeId: 'T1',
            feeCode: 'MINERVAL',
            amountInCents: 4800,
            currency: 'USD',
          ),
          PaymentCorrectionOriginAllocation(
            studentChargeId: 'T2',
            feeCode: 'MINERVAL',
            amountInCents: 4800,
            currency: 'USD',
          ),
        ],
      ),
      originAmounts: MoneyBag.of([Money.parse(9600, 'USD')]),
      originPaidAt: DateTime.utc(2026, 9, 25, 12, 11, 41),
    );

void main() {
  group('créances sans le versement corrigé', () {
    test('ses tranches sont rouvertes, bornes et statut compris', () {
      final charges = chargesWithoutPayment(
        [
          _charge('T1', paid: 4800, status: StudentChargeStatus.paid),
          _charge('T3'),
        ],
        {'T1': 4800},
      );

      expect(charges.first.remainingInCents, 4800);
      expect(charges.first.status, StudentChargeStatus.due);
      expect(charges.last.remainingInCents, 4800);
    });

    test('un versement pas encore remonté rend son pending', () {
      final charges = chargesWithoutPayment(
        [_charge('T1', pending: 4800, status: StudentChargeStatus.paid)],
        {'T1': 2000},
      );

      expect(charges.single.remainingInCents, 2000);
      expect(charges.single.status, StudentChargeStatus.partial);
    });
  });

  group('écart (D8 : neutre)', () {
    test('rend le signe et la devise', () {
      final label = correctionGapLabel(
        MoneyBag.of([Money.parse(5000, 'USD')]),
        MoneyBag.of([Money.parse(15000, 'USD')]),
      );

      expect(label, startsWith('−'));
      expect(label, contains('100'));
    });

    test('aucun écart, aucune phrase', () {
      final bag = MoneyBag.of([Money.parse(5000, 'USD')]);

      expect(correctionGapLabel(bag, bag), isNull);
    });
  });

  group('rien n a changé', () {
    test('mêmes tranches, mêmes montants, même jour', () {
      expect(
        correctionUnchanged(
          correction: _gloredi(),
          replacementCentsByCharge: {'T1': 4800, 'T2': 4800},
          replacementDay: DateTime(2026, 9, 25),
        ),
        isTrue,
      );
    });

    test('un montant différent suffit', () {
      expect(
        correctionUnchanged(
          correction: _gloredi(),
          replacementCentsByCharge: {'T1': 4800, 'T2': 200},
          replacementDay: DateTime(2026, 9, 25),
        ),
        isFalse,
      );
    });

    test('un autre jour suffit', () {
      expect(
        correctionUnchanged(
          correction: _gloredi(),
          replacementCentsByCharge: {'T1': 4800, 'T2': 4800},
          replacementDay: DateTime(2026, 9, 26),
        ),
        isFalse,
      );
    });
  });

  group('date du remplaçant (D2)', () {
    const draft = RecordPaymentDraft(
      studentId: 's-1',
      academicYearId: 'ay-1',
      paidAt: '2026-09-26T08:00:00.000Z',
      allocations: [],
    );

    test('même jour : l instant d origine est repris', () {
      final kept = withOriginInstant(draft, _gloredi(), DateTime(2026, 9, 25));

      expect(kept.paidAt, '2026-09-25T12:11:41Z');
    });

    test('autre jour : la date choisie reste', () {
      final kept = withOriginInstant(draft, _gloredi(), DateTime(2026, 9, 24));

      expect(kept.paidAt, draft.paidAt);
    });
  });

  group('pré-remplissage du formulaire', () {
    final taux = ExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2000000000,
      effectiveFrom: DateTime.utc(2026, 1, 1),
      divergenceBandBp: 200,
    );

    FacturationCollectFormModel modele() =>
        FacturationCollectFormModel.fromCharges(
          charges: [_charge('T1'), _charge('T2'), _charge('T3')],
          rates: FacturationRateBoard(onChanged: () {}),
          nowOf: () => DateTime.utc(2026, 9, 26, 8),
          settlementOf: () =>
              TenderSettlement(rates: [taux], at: DateTime.utc(2026, 9, 26)),
        );

    test('les tranches de l origine, montants posés à la main', () {
      final m = modele()
        ..prefill(
          centsByCharge: {'T1': 4800, 'T2': 200},
          day: DateTime(2026, 9, 25),
        );

      expect([for (final e in m.entries) e.effectiveCents], [4800, 200, 0]);
      expect(m.paidDay, DateTime(2026, 9, 25));
      // Posés comme saisis : aucune ligne ne laisse le comptoir décider.
      expect(m.entries.any((e) => e.tenderIsSource), isFalse);
    });

    test('un montant au-delà du restant est borné', () {
      final m = modele()..prefill(centsByCharge: {'T1': 9999});

      expect(m.entries.first.effectiveCents, 4800);
    });

    test('la devise du tiroir d origine est reprise (D7)', () {
      final m = modele()
        ..prefill(centsByCharge: {'T1': 4800})
        ..prefillTenderCurrencies({'USD': 'CDF'});

      expect(m.entries.first.effectiveTenderCurrency, 'CDF');
      expect(m.entries.first.effectiveCents, 4800);
      // Une tranche non reprise reste dans la devise de sa créance.
      expect(m.entries.last.effectiveTenderCurrency, 'USD');
    });
  });
}

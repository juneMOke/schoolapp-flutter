import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';

/// Le règlement d'un salaire (B3) : statut et reste, dérivés des versements.
void main() {
  PayrollLine line({int net = 22000, int? toPay}) => PayrollLine(
    month: '2026-10',
    staffMemberId: 'm-1',
    currency: 'USD',
    baseInCents: net,
    grossInCents: net,
    netInCents: net,
    payout: toPay == null
        ? null
        : PayrollLinePayout(toPayInCents: toPay, deferredInCents: net - toPay),
  );

  PayrollDisbursement paid(int cents) => PayrollDisbursement(
    id: 'd-$cents',
    month: '2026-10',
    staffMemberId: 'm-1',
    validationGestureId: 'g-v',
    amount: Money(cents, 'USD'),
    mode: PayoutMode.cash,
    paidAt: '2026-10-28T09:00:00.000Z',
  );

  PayrollSettlementStatus status(PayrollLine l, List<int> amounts) =>
      PayrollSettlement(
        line: l,
        disbursements: [for (final a in amounts) paid(a)],
      ).status;

  test('rien versé, acompte, soldé', () {
    expect(status(line(), []), PayrollSettlementStatus.unpaid);
    expect(status(line(), [8800]), PayrollSettlementStatus.partial);
    expect(status(line(), [8800, 13200]), PayrollSettlementStatus.settled);
  });

  test('différé : la part décidée est versée, le reste est un arriéré', () {
    final reduced = line(toPay: 13200);
    final settlement = PayrollSettlement(
      line: reduced,
      disbursements: [paid(13200)],
    );

    expect(settlement.status, PayrollSettlementStatus.deferred);
    expect(settlement.remainingInCents, 8800);
    expect(settlement.plannedRemainingInCents, 0);
    expect(settlement.isDoneThisMonth, isTrue);
    expect(status(reduced, [5000]), PayrollSettlementStatus.partial);
  });

  test(
    'un taux de 0 % : différé sans rien verser ; net nul : rien à verser',
    () {
      expect(status(line(toPay: 0), []), PayrollSettlementStatus.deferred);
      expect(status(line(net: 0), []), PayrollSettlementStatus.nothingToPay);
    },
  );

  test('le versé ne compte que la devise de la ligne', () {
    final settlement = PayrollSettlement(
      line: line(),
      disbursements: [
        paid(8800),
        const PayrollDisbursement(
          id: 'd-cdf',
          month: '2026-10',
          staffMemberId: 'm-1',
          validationGestureId: 'g-v',
          amount: Money(500000, 'CDF'),
          mode: PayoutMode.cash,
          paidAt: '2026-10-28T09:00:00.000Z',
        ),
      ],
    );

    expect(settlement.paidInCents, 8800);
  });
}

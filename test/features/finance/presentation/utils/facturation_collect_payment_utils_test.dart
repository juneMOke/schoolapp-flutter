import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';

StudentCharge charge({required double expected, required double paid}) {
  return StudentCharge(
    id: 'c1',
    studentId: 's1',
    academicYearId: 'y1',
    schoolLevelId: 'l1',
    schoolLevelGroupId: 'g1',
    feeTariffId: 't1',
    feeCode: 'TUITION',
    label: 'Frais',
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'CDF',
    status: StudentChargeStatus.partial,
  );
}

void main() {
  group('chargeRemainingInCents', () {
    test('retourne attendu − payé', () {
      expect(
        chargeRemainingInCents(charge(expected: 500000, paid: 200000)),
        300000,
      );
    });

    test('jamais négatif', () {
      expect(chargeRemainingInCents(charge(expected: 500000, paid: 600000)), 0);
    });
  });

  group('parseAmountToCents', () {
    test('convertit une saisie valide en cents', () {
      expect(parseAmountToCents('5000'), 500000);
    });

    test('retourne 0 pour vide / invalide / négatif', () {
      expect(parseAmountToCents(''), 0);
      expect(parseAmountToCents('abc'), 0);
      expect(parseAmountToCents('-10'), 0);
    });
  });

  group('effectiveAllocationCents', () {
    test('0 si non cochée', () {
      expect(
        effectiveAllocationCents(
          selected: false,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        0,
      );
    });

    test('borné au restant dû quand la saisie dépasse', () {
      expect(
        effectiveAllocationCents(
          selected: true,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        300000,
      );
    });

    test('respecte une saisie inférieure au restant', () {
      expect(
        effectiveAllocationCents(
          selected: true,
          rawAmount: '1000',
          remainingInCents: 300000,
        ),
        100000,
      );
    });
  });

  group('isAmountOverflowing', () {
    test('true uniquement quand cochée et saisie > restant', () {
      expect(
        isAmountOverflowing(
          selected: true,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        isTrue,
      );
      expect(
        isAmountOverflowing(
          selected: true,
          rawAmount: '2000',
          remainingInCents: 300000,
        ),
        isFalse,
      );
      expect(
        isAmountOverflowing(
          selected: false,
          rawAmount: '5000',
          remainingInCents: 300000,
        ),
        isFalse,
      );
    });
  });
}

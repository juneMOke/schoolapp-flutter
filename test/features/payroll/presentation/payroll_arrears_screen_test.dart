import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_screen.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import 'payroll_screen_harness.dart';

/// RH · Paie ▸ Arriérés : le registre et le versement réparti par mois.
void main() {
  setUpAll(() => registerFallbackValue(<PayrollDisbursementDraft>[]));

  PayrollLine line(String id, String month, int net) => PayrollLine(
    month: month,
    staffMemberId: id,
    currency: 'USD',
    baseInCents: net,
    grossInCents: net,
    netInCents: net,
    frozen: true,
  );

  final snapshot = PayrollSnapshot(
    members: [
      member(
        'm-1',
        lastName: 'KABASELE-TSHIMANGA',
        firstName: 'Marie-Béatrice',
      ),
      member('m-2', lastName: 'Mayala', firstName: 'Ruth'),
    ],
    contractsByMember: const {},
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      for (final month in ['2026-08', '2026-09'])
        month: PayrollHeader(
          id: 'p-$month',
          month: month,
          status: PayrollStatus.validated,
          validationGestureId: 'g-$month',
        ),
    },
    variables: const {},
    frozenLines: {
      '2026-08': [line('m-1', '2026-08', 20000), line('m-2', '2026-08', 15000)],
      '2026-09': [line('m-1', '2026-09', 20000), line('m-2', '2026-09', 15000)],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [
      PayrollDisbursement(
        id: 'd-1',
        month: '2026-09',
        staffMemberId: 'm-1',
        validationGestureId: 'g-2026-09',
        amount: Money(5000, 'USD'),
        mode: PayoutMode.cash,
        paidAt: '2026-09-28T09:00:00.000Z',
        signedRegister: true,
      ),
      PayrollDisbursement(
        id: 'd-2',
        month: '2026-08',
        staffMemberId: 'm-2',
        validationGestureId: 'g-2026-08',
        amount: Money(15000, 'USD'),
        mode: PayoutMode.cash,
        paidAt: '2026-08-28T09:00:00.000Z',
        signedRegister: true,
      ),
    ],
    schoolYears: const [(start: '2025-09-01', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  testAtReferenceFormats('Registre des arriérés', (tester, format) async {
    await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      child: const PayrollArrearsScreen(),
    );

    expect(find.text('DETTE SALARIALE'), findsOneWidget);
    expect(find.text('KABASELE-TSHIMANGA Mutombo Marie-Béatrice'), findsOne);
  });

  testWidgets(
    'un versement d arriérés se répartit du plus ancien au plus récent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pumped = await pumpPayrollScreen(
        tester,
        snapshot: snapshot,
        child: const PayrollArrearsScreen(),
      );

      await tester.tap(find.text('KABASELE-TSHIMANGA Mutombo Marie-Béatrice'));
      await tester.pumpAndSettle();
      final signed = find.text("L'agent a signé l'état d'émargement");
      await tester.ensureVisible(signed);
      await tester.pumpAndSettle();
      await tester.tap(signed);
      await tester.pump();
      await tester.tap(find.textContaining('Verser 350'));
      await tester.pumpAndSettle();

      final drafts =
          verify(
                () => pumped.repository.disburseAll(captureAny()),
              ).captured.single
              as List<PayrollDisbursementDraft>;
      expect([for (final d in drafts) d.month], ['2026-08', '2026-09']);
      expect([for (final d in drafts) d.amount.amountInCents], [20000, 15000]);
      expect(drafts.every((d) => d.signedRegister), isTrue);
    },
  );
}

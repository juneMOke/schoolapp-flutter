import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_advances_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_payout_cell.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

const _month = '2026-10';

/// Octobre validé, Ruth payée en partie (100 $ sur 350) ; une avance de
/// novembre encore annulable.
PayrollSnapshot _snapshot() => PayrollSnapshot(
  members: [member('m-1', lastName: 'Mayala', firstName: 'Ruth')],
  contractsByMember: {
    'm-1': [contract('m-1')],
  },
  settings: PayrollSettings.defaults,
  profiles: const {},
  headers: const {
    _month: PayrollHeader(
      id: 'p',
      month: _month,
      status: PayrollStatus.validated,
      validationGestureId: 'g-v',
    ),
  },
  variables: const {},
  frozenLines: {
    _month: [frozenLine('m-1', _month)],
  },
  summaries: const {},
  gestures: const [],
  advances: [advance('m-1', firstMonth: '2026-11')],
  disbursements: const [
    PayrollDisbursement(
      id: 'd-1',
      month: _month,
      staffMemberId: 'm-1',
      validationGestureId: 'g-v',
      amount: Money(10000, 'USD'),
      mode: PayoutMode.cash,
      paidAt: '2026-10-20T10:00:00.000Z',
    ),
  ],
  schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
  shareTraces: const {},
  hasEverSynced: true,
);

/// Les commandes de la paie qu'on actionne ligne après ligne : la pastille
/// « Partiel · reste … » (qui rouvre le versement) et l'annulation d'une
/// avance. Au doigt, 48 dp chacune ; la pastille faisait 20 dp de haut.
void main() {
  testAtReferenceFormats('la pastille du versement est une cible de 48 dp', (
    tester,
    format,
  ) async {
    await pumpPayrollScreen(tester, snapshot: _snapshot());
    await tester.pumpAndSettle();

    final cell = find.byType(PayrollPayoutCell);
    await tester.ensureVisible(cell);
    final target = find.descendant(of: cell, matching: find.byType(InkWell));
    expect(
      tester.getSize(target).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    // Lue comme un bouton, sous son libellé entier (l'espace du montant
    // est insécable : on ne compare que son début).
    final node = tester.getSemantics(target);
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    expect(node.label, startsWith('Partiel · reste 250,00'));
  });

  testAtReferenceFormats("l'annulation d'une avance fait 48 dp au doigt", (
    tester,
    format,
  ) async {
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(),
      child: const PayrollAdvancesScreen(),
    );
    await tester.pumpAndSettle();

    final cancel = find.byTooltip('Annuler cette avance');
    await tester.ensureVisible(cancel);
    final button = find.ancestor(of: cancel, matching: find.byType(IconButton));
    final size = tester.getSize(button);
    expect(size.width, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
  });
}

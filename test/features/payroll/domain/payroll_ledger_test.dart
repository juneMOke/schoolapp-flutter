import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';

void main() {
  PayrollSnapshot snapshot({
    Map<String, PayrollHeader> headers = const {},
    List<PayrollGesture> gestures = const [],
    List<PayrollDisbursement> disbursements = const [],
    List<PayrollSchoolYear> years = const [
      (start: '2025-09-01', end: '2026-07-02'),
      (start: '2026-09-07', end: '2027-07-02'),
    ],
  }) => PayrollSnapshot(
    members: [member('m-1')],
    contractsByMember: {
      'm-1': [contract('m-1')],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: headers,
    variables: const {},
    frozenLines: const {},
    summaries: const {},
    gestures: gestures,
    advances: const [],
    disbursements: disbursements,
    schoolYears: years,
    shareTraces: const {},
    hasEverSynced: true,
  );

  PayrollGesture gesture(
    PayrollGestureKind kind, {
    StaffSyncState state = StaffSyncState.pending,
    String? code,
  }) => PayrollGesture(
    id: 'g-${kind.wire}',
    month: '2026-10',
    kind: kind,
    recordedAt: '2026-10-26T10:00:00Z',
    syncState: state,
    syncErrorCode: code,
  );

  PayrollHeader header(PayrollStatus status, {String month = '2026-10'}) =>
      PayrollHeader(
        id: 'p-$month',
        month: month,
        status: status,
        validationGestureId: status == PayrollStatus.validated ? 'g-v' : null,
      );

  group('statut affiché', () {
    test(
      'un geste en vol l emporte, jamais « validée » sur la foi du poste',
      () {
        final view = PayrollLedger.monthView(
          snapshot(
            headers: {'2026-10': header(PayrollStatus.submitted)},
            gestures: [gesture(PayrollGestureKind.validate)],
          ),
          '2026-10',
        );

        expect(view.phase, PayrollPhase.validating);
        expect(view.canPay, isFalse);
      },
    );

    test('un geste refusé rend le statut serveur et se montre', () {
      final view = PayrollLedger.monthView(
        snapshot(
          headers: {'2026-10': header(PayrollStatus.submitted)},
          gestures: [
            gesture(
              PayrollGestureKind.validate,
              state: StaffSyncState.failed,
              code: PayrollGesture.staleCode,
            ),
          ],
        ),
        '2026-10',
      );

      expect(view.phase, PayrollPhase.submitted);
      expect(view.lastRefusal?.isStale, isTrue);
    });

    test('validée et tous les nets versés : versée', () {
      final view = PayrollLedger.monthView(
        snapshot(
          headers: {'2026-10': header(PayrollStatus.validated)},
          disbursements: [
            const PayrollDisbursement(
              id: 'd-1',
              month: '2026-10',
              staffMemberId: 'm-1',
              validationGestureId: 'g-v',
              amount: Money(35000, 'USD'),
              mode: PayoutMode.cash,
              paidAt: '2026-10-28T10:00:00Z',
              signedRegister: true,
            ),
          ],
        ),
        '2026-10',
      );

      expect(view.phase, PayrollPhase.paid);
      expect(view.reopenBlocker, PayrollBlocker.hasDisbursements);
    });
  });

  group('gardes', () {
    test('la paie précédente existante doit être validée (E9)', () {
      final view = PayrollLedger.monthView(
        snapshot(
          headers: {'2026-09': header(PayrollStatus.draft, month: '2026-09')},
        ),
        '2026-10',
      );

      expect(view.submitBlocker, PayrollBlocker.previousNotValidated);
    });

    test('M−1 dans une année et non clos : validation bloquée', () {
      final view = PayrollLedger.monthView(snapshot(), '2026-10');

      expect(view.attendance, PayrollAttendanceState.open);
      expect(view.validateBlocker, PayrollBlocker.attendanceOpen);
    });

    test('août hors de toute année : compte comme clos (R1, N3)', () {
      final view = PayrollLedger.monthView(snapshot(), '2026-09');

      expect(view.attendance, PayrollAttendanceState.outOfYear);
      expect(view.validateBlocker, isNull);
    });

    test('une année sans dates : la tablette ne tranche pas', () {
      final view = PayrollLedger.monthView(
        snapshot(years: const [(start: null, end: null)]),
        '2026-09',
      );

      expect(view.attendance, PayrollAttendanceState.unverifiable);
      expect(view.validateBlocker, isNull);
    });
  });
}

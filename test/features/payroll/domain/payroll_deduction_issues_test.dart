import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';

const _month = '2026-10';
const _type = PayrollDeductionType(id: 't', label: 'Cartes', sortOrder: 10);

PayrollDeductionEntry _entry({
  int amount = 500,
  String currency = 'USD',
  String type = 't',
  RecordSyncState state = RecordSyncState.synced,
}) => PayrollDeductionEntry(
  staffMemberId: 'm-1',
  deductionTypeId: type,
  amountInCents: amount,
  currency: currency,
  syncState: state,
);

PayrollSnapshot _snapshot(
  List<PayrollDeductionEntry> entries, {
  List<PayrollDeductionType> types = const [_type],
  Map<String, PayrollHeader> headers = const {},
  Map<String, List<PayrollLine>> frozen = const {},
}) => PayrollSnapshot(
  members: [member('m-1')],
  contractsByMember: {
    'm-1': [contract('m-1')],
  },
  settings: PayrollSettings.defaults,
  profiles: const {},
  headers: headers,
  variables: const {},
  deductionTypes: types,
  deductions: {
    _month: {'m-1': entries},
  },
  frozenLines: frozen,
  summaries: const {},
  gestures: const <PayrollGesture>[],
  advances: const [],
  disbursements: const [],
  schoolYears: const [],
  shareTraces: const {},
  hasEverSynced: true,
);

PayrollMonthView _view(PayrollSnapshot snapshot) =>
    PayrollLedger.monthView(snapshot, _month);

void main() {
  test('une saisie ordinaire ne bloque rien', () {
    final view = _view(_snapshot([_entry()]));

    expect(view.submitBlocker, isNull);
    expect(view.deductionIssues.blocker, isNull);
  });

  test('autre devise : soumission et validation bloquées, nommée', () {
    final view = _view(_snapshot([_entry(currency: 'CDF')]));

    expect(view.submitBlocker, PayrollBlocker.deductionCurrency);
    expect(view.validateBlocker, PayrollBlocker.deductionCurrency);
    expect(view.deductionIssues.foreign.single.staffMemberId, 'm-1');
  });

  test('autre devise à 0 : rien ne bloque', () {
    final view = _view(_snapshot([_entry(amount: 0, currency: 'CDF')]));

    expect(view.submitBlocker, isNull);
  });

  test('rubrique inconnue du catalogue : bloque aussi', () {
    final view = _view(_snapshot([_entry(type: 'x')]));

    expect(view.submitBlocker, PayrollBlocker.deductionTypeUnknown);
  });

  test('une saisie refusée se lit, sans bloquer ni compter', () {
    final view = _view(
      _snapshot([_entry(type: 'x', state: RecordSyncState.failed)]),
    );

    expect(view.submitBlocker, isNull);
    expect(view.deductionIssues.refused, hasLength(1));
    expect(view.lines.single.deductions.custom, isEmpty);
  });

  test('une paie figée ne se bloque plus', () {
    final view = _view(
      _snapshot(
        [_entry(currency: 'CDF')],
        headers: const {
          _month: PayrollHeader(
            id: 'p',
            month: _month,
            status: PayrollStatus.validated,
            validationGestureId: 'g',
          ),
        },
        frozen: const {
          _month: [
            PayrollLine(
              month: _month,
              staffMemberId: 'm-1',
              currency: 'USD',
              baseInCents: 100,
              grossInCents: 100,
              netInCents: 100,
              frozen: true,
            ),
          ],
        },
      ),
    );

    expect(view.validateBlocker, isNull);
  });

  test('net = brut − total − avances, avec rubriques', () {
    final line = _view(_snapshot([_entry()])).lines.single;

    expect(
      line.netInCents,
      line.grossInCents - line.deductions.totalInCents - line.advanceInCents,
    );
  });

  test('les cumuls de la fiche comptent les rubriques', () {
    final month = PayrollAgentMonth(
      view: _view(_snapshot(const [])),
      line: const PayrollLine(
        month: _month,
        staffMemberId: 'm-1',
        currency: 'USD',
        baseInCents: 100,
        grossInCents: 100,
        netInCents: 90,
        deductions: PayrollLineDeductions(
          custom: [
            PayrollLineCustomDeduction(
              deductionTypeId: 't',
              label: 'Cartes',
              requestedInCents: 10,
              takenInCents: 10,
            ),
          ],
        ),
      ),
    );

    expect(
      const PayrollAgentTotals(currency: 'USD').add(month).customInCents,
      10,
    );
  });

  test('le livre compte les lignes rognées', () {
    final capacity = _view(_snapshot(const [])).lines.single.netInCents;
    final view = _view(_snapshot([_entry(amount: capacity + 100)]));

    expect(view.trimmedCount, 1);
  });
}

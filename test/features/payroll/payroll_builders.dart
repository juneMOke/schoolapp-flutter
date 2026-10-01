import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

StaffContract contract(
  String memberId, {
  StaffContractKind kind = StaffContractKind.permanent,
  StaffPayMode? payMode,
  int? amount = 35000,
  String currency = 'USD',
  int? bonus,
  String from = '2026-01-01',
  String? endsOn,
  String? id,
  RecordSyncState syncState = RecordSyncState.synced,
  String? correctedAt,
}) => StaffContract(
  id: id ?? 'c-$memberId-$from',
  staffMemberId: memberId,
  kind: kind,
  payMode: payMode,
  effectiveFrom: from,
  endsOn: endsOn,
  amount: amount == null ? null : Money(amount, currency),
  bonus: bonus == null ? null : Money(bonus, currency),
  recordedAt: '2026-01-01T08:00:00.000Z',
  syncState: syncState,
  correctedAt: correctedAt,
);

SalaryAdvance advance(
  String memberId, {
  String id = 'a-1',
  int amount = 10000,
  String currency = 'USD',
  int installments = 1,
  String firstMonth = '2026-10',
  String grantedOn = '2026-10-05',
  RecordSyncState syncState = RecordSyncState.synced,
}) => SalaryAdvance(
  id: id,
  staffMemberId: memberId,
  amount: Money(amount, currency),
  installments: installments,
  firstMonth: firstMonth,
  reason: SalaryAdvanceReason.medical,
  mode: PayoutMode.cash,
  grantedOn: grantedOn,
  syncState: syncState,
);

/// Une ligne figée d'un mois validé, portant la retenue [taken] de [advanceId].
PayrollLine frozenLine(
  String memberId,
  String month, {
  String currency = 'USD',
  int gross = 35000,
  String? advanceId,
  int taken = 0,
}) => PayrollLine(
  month: month,
  staffMemberId: memberId,
  currency: currency,
  baseInCents: gross,
  grossInCents: gross,
  netInCents: gross - taken,
  frozen: true,
  advances: [
    if (advanceId != null)
      PayrollLineAdvance(
        advanceId: advanceId,
        rank: 1,
        installments: 3,
        dueInCents: taken,
        takenInCents: taken,
        carriedInCents: 0,
      ),
  ],
);

import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Une ligne figée telle que le serveur la descend — gardée entière dans
/// `payroll_lines.line`, relue ici. Une ligne sans `formulaVersion` est une
/// ligne v1 : ni retenues fixes, ni versement réduit.
abstract final class PayrollLineJson {
  /// `null` si la ligne est illisible : une ligne tronquée ne s'invente pas.
  static PayrollLine? tryParse(Object? raw, {required String month}) {
    if (raw is! Map) return null;
    final staffMemberId = raw.text('staffMemberId');
    final currency = raw.text('currency');
    final gross = raw.integer('grossInCents');
    final net = raw.integer('netInCents');
    if (staffMemberId == null ||
        currency == null ||
        gross == null ||
        net == null) {
      return null;
    }
    final base = _map(raw['base']);
    final overtime = _map(raw['overtime']);
    final allowance = _map(raw['allowance']);
    final attendance = _map(raw['attendance']);
    final advances = raw['advances'];
    return PayrollLine(
      month: month,
      staffMemberId: staffMemberId,
      contractId: raw.text('contractId'),
      contractKind: StaffContractKind.fromWire(raw.text('contractKind')),
      payMode: StaffPayMode.fromWire(raw.text('payMode')),
      contractFrom: raw.day('contractFrom'),
      currency: CurrencyCode.normalize(currency),
      baseInCents: base.integer('amountInCents') ?? 0,
      baseMinutes: base.integer('minutes'),
      baseRateInCents: base.integer('rateInCents'),
      hoursMonth: base.yearMonth('hoursMonth'),
      overtimeMinutes: overtime.integer('minutes') ?? 0,
      overtimeRateInCents: overtime.integer('rateInCents') ?? 0,
      overtimeInCents: overtime.integer('amountInCents') ?? 0,
      children: allowance.integer('children') ?? 0,
      allowanceInCents: allowance.integer('amountInCents') ?? 0,
      grossInCents: gross,
      netInCents: net,
      formulaVersion: raw.integer('formulaVersion') ?? 1,
      deductions: _deductions(raw['deductions']),
      payout: _payout(raw['payout'], net),
      advances: [
        if (advances is List)
          for (final item in advances)
            if (_advance(item) case final PayrollLineAdvance advance) advance,
      ],
      attendanceMonth: attendance.yearMonth('month'),
      attendance: AttendanceAgentSummary(
        unjustifiedAbsences: attendance.integer('unjustifiedAbsences') ?? 0,
        justifiedAbsences: attendance.integer('justifiedAbsences') ?? 0,
        lates: attendance.integer('lates') ?? 0,
        lateMinutes: attendance.integer('lateMinutes') ?? 0,
        workedMinutes: base.integer('minutes') ?? 0,
      ),
      frozen: true,
    );
  }

  static PayrollLineDeductions _deductions(Object? raw) {
    if (raw is! Map) return PayrollLineDeductions.none;
    return PayrollLineDeductions(
      workDaysDivisor: raw.integer('workDaysDivisor'),
      workedDays: raw.integer('daysWorked'),
      absenceInCents: raw.integer('absenceInCents') ?? 0,
      iprInCents: raw.integer('iprInCents') ?? 0,
      cnssInCents: raw.integer('cnssInCents') ?? 0,
      childcareInCents: raw.integer('childcareInCents') ?? 0,
    );
  }

  /// Sans bloc, tout le net est à verser — un « à verser » au-delà du net ne
  /// se croit pas.
  static PayrollLinePayout? _payout(Object? raw, int net) {
    if (raw is! Map) return null;
    final toPay = raw.integer('toPayInCents');
    if (toPay == null || toPay < 0 || toPay > net) return null;
    return PayrollLinePayout(
      toPayInCents: toPay,
      deferredInCents: net - toPay,
      ratePercent: raw.integer('percent'),
      fixedInCents: raw.integer('fixedInCents'),
      reason: raw.text('reason'),
    );
  }

  static Map<dynamic, dynamic> _map(Object? raw) =>
      raw is Map ? raw : const <String, Object?>{};

  static PayrollLineAdvance? _advance(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('advanceId');
    if (id == null) return null;
    return PayrollLineAdvance(
      advanceId: id,
      rank: raw.integer('rank') ?? 0,
      installments: raw.integer('installments') ?? 0,
      dueInCents: raw.integer('dueInCents') ?? 0,
      takenInCents: raw.integer('takenInCents') ?? 0,
      carriedInCents: raw.integer('carriedInCents') ?? 0,
    );
  }
}

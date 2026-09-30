import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Une ligne figée telle que le serveur la descend — gardée entière dans
/// `payroll_lines.line`, relue ici.
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

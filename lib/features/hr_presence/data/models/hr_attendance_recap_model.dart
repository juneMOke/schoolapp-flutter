import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_json.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';

/// Le récapitulatif pour la paie (`GET /hr/attendance-stats/recap`).
///
/// Calé sur `AttendanceRecapDto` du back (`feat/hr-attendance-stats`,
/// `b6bcd97f` + revue `f8de0fc8`), élargi par la paie au mois M
/// (`feat/payroll-month-m`, L4).
abstract final class HrAttendanceRecapModel {
  static HrAttendanceRecap fromJson(Map<String, dynamic> json) {
    final totals = HrAttendanceJson.map(json['totals']);
    final amounts = totals['amounts'] as List<dynamic>?;
    return HrAttendanceRecap(
      month: json['month'] as String,
      classDays: HrAttendanceJson.count(json, 'classDays'),
      toDate: json['toDate'] as bool,
      closed: json['closed'] as bool,
      closedAt: json['closedAt'] as String?,
      closedBy: json['closedBy'] as String?,
      closable: json['closable'] as bool,
      // Absent d'un serveur d'avant la réouverture : jamais rouvrable.
      reopenable: json['reopenable'] as bool? ?? false,
      absenceDeductionEnabled:
          json['absenceDeductionEnabled'] as bool? ?? false,
      workingDays: (json['workingDays'] as num?)?.toInt() ?? 0,
      payrollStatus: HrRecapPayrollStatus.fromWire(
        json['payrollStatus'] as String?,
      ),
      unscored: HrAttendanceJson.count(json, 'unscored'),
      totals: HrAttendanceRecapTotals(
        presenceRatePct: HrAttendanceJson.rate(totals, 'presenceRatePct'),
        workedMinutes: HrAttendanceJson.count(totals, 'workedMinutes'),
        unjustifiedAbsences: HrAttendanceJson.count(
          totals,
          'unjustifiedAbsences',
        ),
        amounts: amounts == null
            ? null
            : [for (final amount in amounts) _amount(amount)],
      ),
      staff: [
        for (final row in HrAttendanceJson.list(json['staff']))
          HrAttendanceRecapRow(
            agent: HrAttendanceJson.agent(row),
            classDays: HrAttendanceJson.count(row, 'classDays'),
            presences: HrAttendanceJson.count(row, 'presences'),
            late: HrAttendanceJson.count(row, 'late'),
            lateMinutes: HrAttendanceJson.count(row, 'lateMinutes'),
            justifiedAbsences: HrAttendanceJson.count(row, 'justifiedAbsences'),
            unjustifiedAbsences: HrAttendanceJson.count(
              row,
              'unjustifiedAbsences',
            ),
            unscored: HrAttendanceJson.count(row, 'unscored'),
            workedMinutes: HrAttendanceJson.count(row, 'workedMinutes'),
            amount: HrAttendanceJson.money(row['amount']),
            pay: _pay(row),
          ),
      ],
    );
  }

  static int? _cents(Map<String, dynamic> json, String key) =>
      (json[key] as num?)?.toInt();

  /// Les montants d'une ligne : tous `null` sans `hr.pay.read` ou sans ligne
  /// de paie — la devise suffit à le dire. Une devise sans ses montants ne
  /// s'affiche pas en « 0,00 » : la ligne reste sans argent.
  static HrAttendanceRecapPay? _pay(Map<String, dynamic> row) {
    final currency = row['currency'] as String?;
    final base = _cents(row, 'baseInCents');
    final gross = _cents(row, 'grossInCents');
    final grossAfter = _cents(row, 'grossAfterAbsenceInCents');
    if (currency == null || base == null || gross == null) return null;
    if (grossAfter == null) return null;
    return HrAttendanceRecapPay(
      currency: currency,
      baseInCents: base,
      grossInCents: gross,
      grossAfterAbsenceInCents: grossAfter,
      dailyRateInCents: _cents(row, 'dailyRateInCents'),
      absenceDeductionInCents: _cents(row, 'absenceDeductionInCents'),
      hourlyRateInCents: _cents(row, 'hourlyRateInCents'),
    );
  }

  /// Une entrée de `totals.amounts[]` : `amountInCents` (les heures de
  /// vacation) et, depuis la paie au mois M, les montants du mois.
  static HrAttendanceRecapAmount _amount(Object? raw) {
    final json = HrAttendanceJson.map(raw);
    return HrAttendanceRecapAmount(
      currency: json['currency'] as String,
      hoursInCents: _cents(json, 'amountInCents') ?? 0,
      baseInCents: _cents(json, 'baseInCents') ?? 0,
      grossInCents: _cents(json, 'grossInCents') ?? 0,
      absenceDeductionInCents: _cents(json, 'absenceDeductionInCents') ?? 0,
      grossAfterAbsenceInCents: _cents(json, 'grossAfterAbsenceInCents') ?? 0,
    );
  }
}

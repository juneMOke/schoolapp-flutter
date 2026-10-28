import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_json.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';

/// Le récapitulatif pour la paie (`GET /hr/attendance-stats/recap`).
///
/// Calé sur `AttendanceRecapDto` du back (`feat/hr-attendance-stats`,
/// `b6bcd97f` + revue `f8de0fc8`).
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
            : [
                for (final amount in amounts)
                  HrAttendanceJson.money(amount) as Money,
              ],
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
          ),
      ],
    );
  }
}

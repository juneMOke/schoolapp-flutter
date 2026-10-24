import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_json.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';

/// Miroirs de `StaffAttendanceMonthDto` et `StaffAttendanceYearDto`
/// (`GET /hr/attendance-stats/staff/{id}` et `…/year`).
abstract final class HrAttendanceAgentModel {
  static HrAttendanceAgentMonth monthFromJson(Map<String, dynamic> json) =>
      HrAttendanceAgentMonth(
        month: json['month'] as String,
        classDays: HrAttendanceJson.count(json, 'classDays'),
        toDate: json['toDate'] as bool,
        agent: HrAttendanceJson.agent(HrAttendanceJson.map(json['agent'])),
        profile: HrAttendanceJson.profile(json),
        kpis: HrAttendanceJson.kpis(HrAttendanceJson.map(json['kpis'])),
        days: [
          for (final day in HrAttendanceJson.list(json['days'])) _day(day),
        ],
        trend: [
          for (final point in HrAttendanceJson.list(json['trend']))
            HrAttendanceTrendPoint(
              month: point['month'] as String,
              presenceRatePct: HrAttendanceJson.rate(point, 'presenceRatePct'),
            ),
        ],
      );

  static HrAttendanceAgentYear yearFromJson(Map<String, dynamic> json) =>
      HrAttendanceAgentYear(
        schoolYear: json['schoolYear'] == null
            ? null
            : schoolYear(HrAttendanceJson.map(json['schoolYear'])),
        agent: HrAttendanceJson.agent(HrAttendanceJson.map(json['agent'])),
        profile: HrAttendanceJson.profile(json),
        kpis: HrAttendanceJson.kpis(HrAttendanceJson.map(json['kpis'])),
        months: [
          for (final month in HrAttendanceJson.list(json['months']))
            HrAttendanceMonthSummary(
              month: month['month'] as String,
              state: HrAttendanceMonthState.fromWire(month['state'] as String?),
              classDays: HrAttendanceJson.count(month, 'classDays'),
              scored: HrAttendanceJson.count(month, 'scored'),
              presenceRatePct: HrAttendanceJson.rate(month, 'presenceRatePct'),
              lateRatePct: HrAttendanceJson.rate(month, 'lateRatePct'),
              absenceRatePct: HrAttendanceJson.rate(month, 'absenceRatePct'),
              profile: HrAttendanceJson.profile(month),
            ),
        ],
      );

  static HrSchoolYear schoolYear(Map<String, dynamic> json) => HrSchoolYear(
    name: json['name'] as String,
    from: json['from'] as String,
    to: json['to'] as String,
  );

  /// Un statut inconnu se lit « à pointer » : le jour reste affiché, sans
  /// rien affirmer.
  static HrAttendanceDay _day(Map<String, dynamic> json) => HrAttendanceDay(
    date: json['date'] as String,
    status:
        StaffPresenceWire.fromStaffWire(json['status'] as String?) ??
        PresenceStatus.none,
    arrival: json['arrivalTime'] as String?,
    departure: json['departureTime'] as String?,
    lateMinutes: HrAttendanceJson.count(json, 'lateMinutes'),
    workedMinutes: HrAttendanceJson.count(json, 'workedMinutes'),
    reason: StaffAbsenceReason.fromWire(json['justificationReason'] as String?),
    note: json['justificationNote'] as String?,
    future: json['future'] as bool,
  );
}

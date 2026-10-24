import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_json.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';

/// Miroir de `AttendanceDashboardDto` (`GET /hr/attendance-stats`).
abstract final class HrAttendanceDashboardModel {
  static HrAttendanceDashboard fromJson(Map<String, dynamic> json) =>
      HrAttendanceDashboard(
        from: json['from'] as String,
        to: json['to'] as String,
        classDays: HrAttendanceJson.count(json, 'classDays'),
        staffCount: HrAttendanceJson.count(json, 'staffCount'),
        granularity: HrAttendanceGranularity.fromWire(
          json['granularity'] as String?,
        ),
        kpis: HrAttendanceJson.kpis(HrAttendanceJson.map(json['kpis'])),
        series: [
          for (final bar in HrAttendanceJson.list(json['series']))
            HrAttendanceBar(
              key: bar['key'] as String,
              scored: HrAttendanceJson.count(bar, 'scored'),
              presences: HrAttendanceJson.count(bar, 'presences'),
              absences: HrAttendanceJson.count(bar, 'absences'),
              presenceRatePct: HrAttendanceJson.rate(bar, 'presenceRatePct'),
              absenceRatePct: HrAttendanceJson.rate(bar, 'absenceRatePct'),
            ),
        ],
        // Identité et compteurs à plat, dans l'ordre du serveur.
        staff: [
          for (final row in HrAttendanceJson.list(json['staff']))
            HrAttendanceStaffRow(
              agent: HrAttendanceJson.agent(row),
              kpis: HrAttendanceJson.kpis(row),
            ),
        ],
      );
}

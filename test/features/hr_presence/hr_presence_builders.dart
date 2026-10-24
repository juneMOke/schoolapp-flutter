import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Des entités de statistiques de présence, valeurs par défaut lisibles.
HrAttendanceKpis kpisOf({
  int scored = 20,
  int presences = 18,
  int? rate = 90,
  int late = 2,
  int lateMinutes = 31,
  int? punctuality = 89,
  int justified = 1,
  int unjustified = 1,
  int unscored = 0,
}) => HrAttendanceKpis(
  scored: scored,
  presences: presences,
  presenceRatePct: rate,
  absenceRatePct: rate == null ? null : 100 - rate,
  late: late,
  lateRatePct: null,
  lateMinutes: lateMinutes,
  punctualityPct: punctuality,
  justifiedAbsences: justified,
  unjustifiedAbsences: unjustified,
  unscored: unscored,
  workedMinutes: 0,
);

HrAttendanceStaffRow staffRow(
  String id, {
  required String lastName,
  String? firstName,
  String? jobTitle = 'Enseignant',
  HrAttendanceKpis? kpis,
}) => HrAttendanceStaffRow(
  agent: HrAttendanceAgent(
    staffMemberId: id,
    staffNumber: 'AG-$id',
    lastName: lastName,
    firstName: firstName,
    jobTitle: jobTitle,
    category: StaffCategory.teacher,
  ),
  kpis: kpis ?? kpisOf(),
);

HrAttendanceBar barOf(String key, {int scored = 10, int? rate = 90}) =>
    HrAttendanceBar(
      key: key,
      scored: rate == null ? 0 : scored,
      presences: rate == null ? 0 : scored * rate ~/ 100,
      absences: rate == null ? 0 : scored - scored * rate ~/ 100,
      presenceRatePct: rate,
      absenceRatePct: rate == null ? null : 100 - rate,
    );

HrAttendanceDashboard dashboardOf({
  String from = '2026-10-01',
  String to = '2026-10-23',
  int classDays = 17,
  int staffCount = 3,
  HrAttendanceGranularity granularity = HrAttendanceGranularity.day,
  HrAttendanceKpis? kpis,
  List<HrAttendanceBar>? series,
  List<HrAttendanceStaffRow>? staff,
}) => HrAttendanceDashboard(
  from: from,
  to: to,
  classDays: classDays,
  staffCount: staffCount,
  granularity: granularity,
  kpis: kpis ?? kpisOf(),
  series:
      series ??
      [
        barOf('2026-10-21', rate: 86),
        barOf('2026-10-22', rate: 100),
        barOf('2026-10-23', rate: null),
      ],
  staff:
      staff ??
      [
        staffRow(
          'a-1',
          lastName: 'MWAMBA',
          firstName: 'Clarisse',
          jobTitle: 'Secrétaire',
          kpis: kpisOf(rate: 78, unjustified: 3),
        ),
        staffRow('a-2', lastName: 'KALALA', firstName: 'Didier'),
        staffRow(
          'a-3',
          lastName: 'MAYALA',
          firstName: 'Ruth',
          kpis: kpisOf(rate: 100, late: 0, justified: 0, unjustified: 0),
        ),
      ],
);

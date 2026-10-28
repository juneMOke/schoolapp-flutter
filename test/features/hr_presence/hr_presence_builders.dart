import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
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

/// Le mois d'octobre 2026 d'un agent : trois jours pointés (présent, retard
/// de 12 min, absence non justifiée), le reste à venir.
HrAttendanceAgentMonth agentMonthOf({
  String id = 'a-1',
  String month = '2026-10',
  StaffPayMode? payMode,
  HrAttendanceKpis? kpis,
  List<HrAttendanceDay>? days,
}) => HrAttendanceAgentMonth(
  month: month,
  classDays: 17,
  toDate: true,
  agent: HrAttendanceAgent(
    staffMemberId: id,
    staffNumber: 'CF-AG-0012',
    lastName: 'MWAMBA',
    middleName: 'ILUNGA',
    firstName: 'Clarisse',
    jobTitle: 'Secrétaire',
    category: StaffCategory.administrative,
    contractKind: StaffContractKind.permanent,
    payMode: payMode,
  ),
  profile: PresenceProfile.absentee,
  kpis:
      kpis ??
      kpisOf(
        scored: 3,
        presences: 2,
        rate: 67,
        late: 1,
        lateMinutes: 12,
        justified: 0,
        unjustified: 1,
        unscored: 14,
      ),
  days:
      days ??
      [
        const HrAttendanceDay(
          date: '2026-10-01',
          status: PresenceStatus.present,
          arrival: '07:25',
          lateMinutes: 0,
          workedMinutes: 0,
          future: false,
        ),
        const HrAttendanceDay(
          date: '2026-10-02',
          status: PresenceStatus.late,
          arrival: '07:52',
          lateMinutes: 12,
          workedMinutes: 0,
          future: false,
        ),
        const HrAttendanceDay(
          date: '2026-10-05',
          status: PresenceStatus.absent,
          lateMinutes: 0,
          workedMinutes: 0,
          future: false,
        ),
        for (final d in ['06', '07', '08', '09'])
          HrAttendanceDay(
            date: '2026-10-$d',
            status: PresenceStatus.none,
            lateMinutes: 0,
            workedMinutes: 0,
            future: true,
          ),
      ],
  trend: const [
    HrAttendanceTrendPoint(month: '2026-09', presenceRatePct: 95),
    HrAttendanceTrendPoint(month: '2026-10', presenceRatePct: 67),
  ],
);

HrAttendanceProfileRow profileRow(
  String id, {
  required String lastName,
  String? firstName,
  String? jobTitle = 'Enseignant',
  StaffCategory category = StaffCategory.teacher,
  PresenceProfile profile = PresenceProfile.regular,
  int? presence = 92,
  int? late = 6,
  int? absent = 8,
}) => HrAttendanceProfileRow(
  agent: HrAttendanceAgent(
    staffMemberId: id,
    staffNumber: 'AG-$id',
    lastName: lastName,
    firstName: firstName,
    jobTitle: jobTitle,
    category: category,
  ),
  scored: 17,
  presenceRatePct: presence,
  lateRatePct: late,
  absenceRatePct: absent,
  profile: profile,
);

HrAttendanceProfiles profilesOf({
  String? month = '2026-10',
  int classDays = 17,
  List<HrAttendanceProfileRow>? staff,
}) => HrAttendanceProfiles(
  month: month,
  schoolYear: const HrSchoolYear(
    name: '2026-2027',
    from: '2026-09-01',
    to: '2027-06-30',
  ),
  from: month == null ? '2026-09-01' : '$month-01',
  to: '2026-10-23',
  classDays: classDays,
  profileCounts: const {},
  staff:
      staff ??
      [
        profileRow(
          'a-1',
          lastName: 'MWAMBA',
          firstName: 'Clarisse',
          jobTitle: 'Secrétaire',
          category: StaffCategory.administrative,
          profile: PresenceProfile.absentee,
          presence: 79,
          late: 9,
          absent: 21,
        ),
        profileRow(
          'a-2',
          lastName: 'MAYALA',
          firstName: 'Ruth',
          profile: PresenceProfile.exemplary,
          presence: 100,
          late: 0,
          absent: 0,
        ),
        profileRow('a-3', lastName: 'KALALA', firstName: 'Didier'),
      ],
);

HrAttendanceAgentYear agentYearOf({String id = 'a-1'}) => HrAttendanceAgentYear(
  schoolYear: const HrSchoolYear(
    name: '2026-2027',
    from: '2026-09-01',
    to: '2027-06-30',
  ),
  agent: agentMonthOf(id: id).agent,
  profile: PresenceProfile.regular,
  kpis: kpisOf(),
  months: const [
    HrAttendanceMonthSummary(
      month: '2026-09',
      state: HrAttendanceMonthState.classMonth,
      classDays: 22,
      scored: 22,
      presenceRatePct: 95,
      lateRatePct: 5,
      absenceRatePct: 5,
      profile: PresenceProfile.regular,
    ),
    HrAttendanceMonthSummary(
      month: '2026-10',
      state: HrAttendanceMonthState.classMonth,
      classDays: 17,
      scored: 3,
      presenceRatePct: 67,
      lateRatePct: 33,
      absenceRatePct: 33,
      profile: PresenceProfile.absentee,
    ),
    HrAttendanceMonthSummary(
      month: '2026-11',
      state: HrAttendanceMonthState.future,
      classDays: 0,
      scored: 0,
      presenceRatePct: null,
      lateRatePct: null,
      absenceRatePct: null,
      profile: PresenceProfile.notEvaluated,
    ),
  ],
);

HrAttendanceRecapRow recapRow(
  String id, {
  required String lastName,
  String? firstName,
  StaffContractKind? contract = StaffContractKind.permanent,
  StaffPayMode? payMode,
  int presences = 15,
  int late = 1,
  int lateMinutes = 12,
  int justified = 1,
  int unjustified = 0,
  int unscored = 1,
  int workedMinutes = 0,
  Money? amount,
}) => HrAttendanceRecapRow(
  agent: HrAttendanceAgent(
    staffMemberId: id,
    staffNumber: 'AG-$id',
    lastName: lastName,
    firstName: firstName,
    jobTitle: 'Enseignant',
    category: StaffCategory.teacher,
    contractKind: contract,
    payMode: payMode,
  ),
  classDays: 17,
  presences: presences,
  late: late,
  lateMinutes: lateMinutes,
  justifiedAbsences: justified,
  unjustifiedAbsences: unjustified,
  unscored: unscored,
  workedMinutes: workedMinutes,
  amount: amount,
);

HrAttendanceRecap recapOf({
  String month = '2026-10',
  int classDays = 17,
  bool toDate = true,
  bool closed = false,
  bool closable = false,
  bool reopenable = false,
  bool withAmounts = true,
  List<HrAttendanceRecapRow>? staff,
}) => HrAttendanceRecap(
  month: month,
  classDays: classDays,
  toDate: toDate,
  closed: closed,
  closedAt: closed ? '2026-10-31T15:05:00Z' : null,
  closedBy: closed ? 'Mme la Directrice' : null,
  closable: closable,
  reopenable: reopenable,
  unscored: 6,
  totals: HrAttendanceRecapTotals(
    presenceRatePct: 92,
    workedMinutes: 2760,
    unjustifiedAbsences: 11,
    amounts: withAmounts ? const [Money(36800, 'USD')] : null,
  ),
  staff:
      staff ??
      [
        recapRow(
          'a-1',
          lastName: 'MWAMBA',
          firstName: 'Clarisse',
          unjustified: 3,
        ),
        recapRow(
          'a-2',
          lastName: 'KALALA',
          firstName: 'Didier',
          contract: StaffContractKind.vacataire,
          payMode: StaffPayMode.hourly,
          unscored: 0,
          workedMinutes: 1200,
          amount: withAmounts ? const Money(16000, 'USD') : null,
        ),
        recapRow(
          'a-3',
          lastName: 'MAYALA',
          firstName: 'Ruth',
          contract: StaffContractKind.conventionne,
        ),
      ],
);

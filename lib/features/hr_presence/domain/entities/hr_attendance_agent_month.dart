import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';

/// Un jour de classe du mois d'un agent.
///
/// [status] vaut « à pointer » pour un jour non pointé comme pour un jour à
/// venir ; [future] les distingue.
class HrAttendanceDay extends Equatable {
  /// `AAAA-MM-JJ`.
  final String date;
  final PresenceStatus status;

  /// `HH:mm`.
  final String? arrival;
  final String? departure;
  final int lateMinutes;
  final int workedMinutes;
  final StaffAbsenceReason? reason;
  final String? note;
  final bool future;

  const HrAttendanceDay({
    required this.date,
    required this.status,
    this.arrival,
    this.departure,
    required this.lateMinutes,
    required this.workedMinutes,
    this.reason,
    this.note,
    required this.future,
  });

  /// Un retard ou une absence : la liste des incidents du mois.
  bool get isIncident => status.isIncident;

  /// Justifié : un motif est posé.
  bool get isJustified => reason != null;

  @override
  List<Object?> get props => [
    date,
    status,
    arrival,
    departure,
    lateMinutes,
    workedMinutes,
    reason,
    note,
    future,
  ];
}

/// Le taux de présence d'un mois de la tendance ; `null` sans pointage.
class HrAttendanceTrendPoint extends Equatable {
  /// `AAAA-MM`.
  final String month;
  final int? presenceRatePct;

  const HrAttendanceTrendPoint({
    required this.month,
    required this.presenceRatePct,
  });

  @override
  List<Object?> get props => [month, presenceRatePct];
}

/// Le mois d'un agent (`GET /hr/attendance-stats/staff/{id}?month=`) : le
/// détail du tableau de bord et la vue mensuelle de la fiche individuelle.
class HrAttendanceAgentMonth extends Equatable {
  /// `AAAA-MM`.
  final String month;
  final int classDays;

  /// Mois en cours : compté jusqu'à aujourd'hui.
  final bool toDate;
  final HrAttendanceAgent agent;
  final PresenceProfile profile;
  final HrAttendanceKpis kpis;

  /// Un élément par jour de classe du mois, dans l'ordre.
  final List<HrAttendanceDay> days;

  /// Les six derniers mois de classe jusqu'à [month].
  final List<HrAttendanceTrendPoint> trend;

  const HrAttendanceAgentMonth({
    required this.month,
    required this.classDays,
    required this.toDate,
    required this.agent,
    required this.profile,
    required this.kpis,
    required this.days,
    required this.trend,
  });

  /// Les retards et absences du mois, dans l'ordre des jours.
  List<HrAttendanceDay> get incidents => [
    for (final day in days)
      if (day.isIncident) day,
  ];

  @override
  List<Object?> get props => [
    month,
    classDays,
    toDate,
    agent,
    profile,
    kpis,
    days,
    trend,
  ];
}

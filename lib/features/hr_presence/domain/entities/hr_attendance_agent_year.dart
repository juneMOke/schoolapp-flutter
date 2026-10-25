import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';

/// L'année scolaire d'une réponse : son nom et ses bornes (`AAAA-MM-JJ`).
class HrSchoolYear extends Equatable {
  final String name;
  final String from;
  final String to;

  const HrSchoolYear({
    required this.name,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [name, from, to];
}

/// L'état d'un mois de l'année scolaire.
enum HrAttendanceMonthState {
  /// Au moins un jour de classe passé.
  classMonth('CLASS'),

  /// Aucun jour de classe : vacances.
  holiday('HOLIDAY'),

  /// Pas encore commencé.
  future('FUTURE');

  const HrAttendanceMonthState(this.wire);

  final String wire;

  /// Une valeur inconnue se lit « à venir » : le mois reste désactivé plutôt
  /// que d'ouvrir une vue sans données.
  static HrAttendanceMonthState fromWire(String? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    return future;
  }
}

/// Une ligne de la vue annuelle : un mois, ses taux et son profil.
class HrAttendanceMonthSummary extends Equatable {
  /// `AAAA-MM`.
  final String month;
  final HrAttendanceMonthState state;
  final int classDays;
  final int scored;
  final int? presenceRatePct;
  final int? lateRatePct;
  final int? absenceRatePct;
  final PresenceProfile profile;

  const HrAttendanceMonthSummary({
    required this.month,
    required this.state,
    required this.classDays,
    required this.scored,
    required this.presenceRatePct,
    required this.lateRatePct,
    required this.absenceRatePct,
    required this.profile,
  });

  /// Un mois de vacances ou à venir ne s'ouvre pas.
  bool get isOpenable => state == HrAttendanceMonthState.classMonth;

  @override
  List<Object?> get props => [
    month,
    state,
    classDays,
    scored,
    presenceRatePct,
    lateRatePct,
    absenceRatePct,
    profile,
  ];
}

/// L'année scolaire courante d'un agent, mois par mois
/// (`GET /hr/attendance-stats/staff/{id}/year`).
class HrAttendanceAgentYear extends Equatable {
  /// `null` : l'école n'a pas d'année scolaire en cours (entre deux
  /// années) — ni mois, ni chiffres.
  final HrSchoolYear? schoolYear;
  final HrAttendanceAgent agent;
  final PresenceProfile profile;
  final HrAttendanceKpis kpis;

  /// De septembre à juin — les bornes de l'année, pas un calendrier en dur.
  final List<HrAttendanceMonthSummary> months;

  const HrAttendanceAgentYear({
    required this.schoolYear,
    required this.agent,
    required this.profile,
    required this.kpis,
    required this.months,
  });

  @override
  List<Object?> get props => [schoolYear, agent, profile, kpis, months];
}

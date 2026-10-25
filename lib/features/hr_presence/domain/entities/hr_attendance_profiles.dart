import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';

/// La portée de la fiche individuelle : un mois, ou l'année scolaire en cours.
class HrProfileScope extends Equatable {
  /// `AAAA-MM`, ou `null` pour l'année.
  final String? month;

  const HrProfileScope.month(String this.month);

  const HrProfileScope.year() : month = null;

  bool get isYear => month == null;

  @override
  List<Object?> get props => [month];
}

/// Une ligne de la liste du personnel de la fiche : ses trois taux et son
/// profil sur la portée choisie.
class HrAttendanceProfileRow extends Equatable {
  final HrAttendanceAgent agent;
  final int scored;
  final int? presenceRatePct;
  final int? lateRatePct;
  final int? absenceRatePct;
  final PresenceProfile profile;

  const HrAttendanceProfileRow({
    required this.agent,
    required this.scored,
    required this.presenceRatePct,
    required this.lateRatePct,
    required this.absenceRatePct,
    required this.profile,
  });

  @override
  List<Object?> get props => [
    agent,
    scored,
    presenceRatePct,
    lateRatePct,
    absenceRatePct,
    profile,
  ];
}

/// La liste de la fiche individuelle (`GET /hr/attendance-stats/profiles`).
///
/// [staff] arrive dans l'ordre alphabétique ; recherche, catégorie et profil
/// se filtrent sur la tablette.
class HrAttendanceProfiles extends Equatable {
  /// `AAAA-MM` sur un mois, `null` sur l'année.
  final String? month;
  final HrSchoolYear? schoolYear;
  final String from;
  final String to;
  final int classDays;

  /// Un compte pour chacun des cinq profils, zéro compris.
  final Map<PresenceProfile, int> profileCounts;
  final List<HrAttendanceProfileRow> staff;

  const HrAttendanceProfiles({
    required this.month,
    required this.schoolYear,
    required this.from,
    required this.to,
    required this.classDays,
    required this.profileCounts,
    required this.staff,
  });

  @override
  List<Object?> get props => [
    month,
    schoolYear,
    from,
    to,
    classDays,
    profileCounts,
    staff,
  ];
}

import 'package:equatable/equatable.dart';

/// Les compteurs de présence d'une période — de l'école entière ou d'un seul
/// agent, la même forme.
///
/// Les taux sont des entiers en %, arrondis par le serveur, et `null` quand
/// rien n'est pointé : l'écran écrit alors « — », jamais « 0 % ».
class HrAttendanceKpis extends Equatable {
  /// Jours-agent pointés (statut autre que « à pointer »).
  final int scored;

  /// Présent ou en retard.
  final int presences;
  final int? presenceRatePct;
  final int? absenceRatePct;
  final int late;
  final int? lateRatePct;
  final int lateMinutes;

  /// À l'heure parmi les présences.
  final int? punctualityPct;
  final int justifiedAbsences;
  final int unjustifiedAbsences;

  /// Jours-agent attendus et non pointés — jamais un vacataire à l'heure.
  final int unscored;

  /// Minutes prestées des vacataires à l'heure.
  final int workedMinutes;

  const HrAttendanceKpis({
    required this.scored,
    required this.presences,
    required this.presenceRatePct,
    required this.absenceRatePct,
    required this.late,
    required this.lateRatePct,
    required this.lateMinutes,
    required this.punctualityPct,
    required this.justifiedAbsences,
    required this.unjustifiedAbsences,
    required this.unscored,
    required this.workedMinutes,
  });

  int get absences => justifiedAbsences + unjustifiedAbsences;

  @override
  List<Object?> get props => [
    scored,
    presences,
    presenceRatePct,
    absenceRatePct,
    late,
    lateRatePct,
    lateMinutes,
    punctualityPct,
    justifiedAbsences,
    unjustifiedAbsences,
    unscored,
    workedMinutes,
  ];
}

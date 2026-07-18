import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';

/// Statistiques d'assiduité d'un élève calculées **en local** (AF-3, contrat
/// 1.2.0 §5). Dénominateur = **jours réellement appelés** de sa classe sur la
/// période (COUNT des sessions), numérateur = ses absences :
/// `présences = joursAppeles − absences`, `taux = présences / joursAppeles`.
///
/// ⚠ Invariant #7 : n'a de sens que si [bootstrapComplete]. Un demi-pull
/// donnerait « 4 absences ce mois » au lieu de 12 — faux mais plausible, donc
/// indétectable. L'UI ne doit afficher les chiffres que si [available].
///
/// ⚠ Écart connu borné : un élève **transféré** de classe n'a pas d'historique
/// de transfert (non livré côté back) → « sa classe » = la classe courante, le
/// taux par élève d'un transféré est approché. Le taux agrégé (back-office)
/// reste exact via `expectedCount`.
class StudentAttendanceStats extends Equatable {
  final StatsPeriod period;

  /// Bornes calendaires de la période (nulles pour l'année entière).
  final DateTime? from;
  final DateTime? to;

  /// Jours où la classe a été appelée sur la période (dénominateur).
  final int daysCalled;

  /// Absences de l'élève sur la période (numérateur).
  final int absences;

  /// Prérequis des statistiques : l'année entière est en base (invariant #7).
  final bool bootstrapComplete;

  /// Fraîcheur du dernier pull (ADR-002), à afficher avec les chiffres.
  final int? syncedAt;

  const StudentAttendanceStats({
    required this.period,
    this.from,
    this.to,
    required this.daysCalled,
    required this.absences,
    required this.bootstrapComplete,
    this.syncedAt,
  });

  /// Les chiffres sont fiables (à afficher) uniquement si le bootstrap est fait.
  bool get available => bootstrapComplete;

  int get present => (daysCalled - absences).clamp(0, daysCalled);

  /// Taux [0..1] ; `null` si aucun jour appelé (pas de division par zéro, pas de
  /// faux 100 %).
  double? get rate => daysCalled == 0 ? null : present / daysCalled;

  @override
  List<Object?> get props => [
    period,
    from,
    to,
    daysCalled,
    absences,
    bootstrapComplete,
    syncedAt,
  ];
}

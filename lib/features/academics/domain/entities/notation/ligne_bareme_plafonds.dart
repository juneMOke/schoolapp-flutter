import 'package:equatable/equatable.dart';

/// Plafonds de saisie de la ligne de barème du cours (bundle
/// `grades-referential`, lecture seule). Une branche SANS examen porte
/// `maxExamenParPeriodeScolaire` à **0** (contrat Saisie des notes) ; `null`,
/// l'ancienne forme, reste lu pareil tant qu'un bundle d'avant la bascule du
/// barème traîne en cache. Le type `EXAMEN` y est grisé à la création.
class LigneBaremePlafonds extends Equatable {
  final int maxJournalierParSousPeriode;
  final int? maxExamenParPeriodeScolaire;

  const LigneBaremePlafonds({
    required this.maxJournalierParSousPeriode,
    this.maxExamenParPeriodeScolaire,
  });

  /// Vrai si la branche n'a pas d'examen.
  bool get sansExamen => (maxExamenParPeriodeScolaire ?? 0) == 0;

  @override
  List<Object?> get props => [
    maxJournalierParSousPeriode,
    maxExamenParPeriodeScolaire,
  ];
}

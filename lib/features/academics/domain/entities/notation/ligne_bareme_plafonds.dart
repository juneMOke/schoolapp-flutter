import 'package:equatable/equatable.dart';

/// Plafonds de saisie de la ligne de barème du cours (bundle
/// `grades-referential`, lecture seule). [maxExamenParPeriodeScolaire]
/// **nullable** = branche SANS examen (jamais traité comme 0) → le type
/// `EXAMEN` est grisé à la création.
class LigneBaremePlafonds extends Equatable {
  final int maxJournalierParSousPeriode;
  final int? maxExamenParPeriodeScolaire;

  const LigneBaremePlafonds({
    required this.maxJournalierParSousPeriode,
    this.maxExamenParPeriodeScolaire,
  });

  @override
  List<Object?> get props => [
    maxJournalierParSousPeriode,
    maxExamenParPeriodeScolaire,
  ];
}

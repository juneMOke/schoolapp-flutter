import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/examen_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

/// Notation d'une période scolaire (semestre / trimestre) : ses sous-périodes et
/// l'examen de période. [examen] est `null` tant qu'aucune évaluation EXAMEN
/// n'est rattachée.
class PeriodeNotation extends Equatable {
  final String periodeScolaireId;
  final int ordre;
  final StatutPeriode statut;
  final List<SousPeriodeNotation> sousPeriodes;
  final ExamenNotation? examen;

  const PeriodeNotation({
    required this.periodeScolaireId,
    required this.ordre,
    required this.statut,
    required this.sousPeriodes,
    this.examen,
  });

  @override
  List<Object?> get props => [
    periodeScolaireId,
    ordre,
    statut,
    sousPeriodes,
    examen,
  ];
}

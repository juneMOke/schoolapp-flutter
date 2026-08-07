import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/chapitre_option.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/ligne_bareme_plafonds.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';

/// Détail de notation d'un cours par période (semestre / trimestre) puis
/// sous-période.
class CoursNotationDetail extends Equatable {
  final String coursId;
  final String classroomId;
  final String? brancheNom;

  /// Nombre d'élèves inscrits dans la classe.
  final int effectif;
  final List<PeriodeNotation> periodes;

  /// Plafonds de saisie de la ligne de barème (bundle `grades-referential`) —
  /// `null` si la ligne de barème n'est pas encore en cache (prévention
  /// dégradée le temps du premier pull).
  final LigneBaremePlafonds? plafonds;

  /// Chapitres du cours cochables à la création d'une évaluation (bundle
  /// `grades-referential`), triés par `ordre`.
  final List<ChapitreOption> chapitresDisponibles;

  const CoursNotationDetail({
    required this.coursId,
    required this.classroomId,
    this.brancheNom,
    required this.effectif,
    required this.periodes,
    this.plafonds,
    this.chapitresDisponibles = const [],
  });

  @override
  List<Object?> get props => [
    coursId,
    classroomId,
    brancheNom,
    effectif,
    periodes,
    plafonds,
    chapitresDisponibles,
  ];
}

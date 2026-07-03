import 'package:equatable/equatable.dart';
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

  const CoursNotationDetail({
    required this.coursId,
    required this.classroomId,
    this.brancheNom,
    required this.effectif,
    required this.periodes,
  });

  @override
  List<Object?> get props => [
    coursId,
    classroomId,
    brancheNom,
    effectif,
    periodes,
  ];
}

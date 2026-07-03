import 'package:equatable/equatable.dart';

sealed class EleveSearchEvent extends Equatable {
  const EleveSearchEvent();
}

/// Demande une recherche roster scopée classe (« Retrouver l'élève »).
///
/// [nom] / [postnom] / [prenom] optionnels, combinés en ET côté backend
/// (chaîne vide traitée comme absente).
class EleveSearchRequested extends EleveSearchEvent {
  final String classroomId;
  final String academicYearId;
  final String? nom;
  final String? postnom;
  final String? prenom;

  const EleveSearchRequested({
    required this.classroomId,
    required this.academicYearId,
    this.nom,
    this.postnom,
    this.prenom,
  });

  @override
  List<Object?> get props => [
    classroomId,
    academicYearId,
    nom,
    postnom,
    prenom,
  ];
}

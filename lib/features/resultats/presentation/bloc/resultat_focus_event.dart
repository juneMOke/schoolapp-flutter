import 'package:equatable/equatable.dart';

sealed class ResultatFocusEvent extends Equatable {
  const ResultatFocusEvent();
}

/// Demande le chargement de la vue focus d'un élève.
///
/// Émis au clic sur une ligne classée, ou à la résolution d'une recherche à un
/// seul résultat.
class ResultatFocusRequested extends ResultatFocusEvent {
  final String classroomId;
  final String periodeScolaireId;
  final String studentId;

  const ResultatFocusRequested({
    required this.classroomId,
    required this.periodeScolaireId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [classroomId, periodeScolaireId, studentId];
}

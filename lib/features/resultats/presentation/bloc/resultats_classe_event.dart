import 'package:equatable/equatable.dart';

sealed class ResultatsClasseEvent extends Equatable {
  const ResultatsClasseEvent();
}

/// Demande le chargement de la vue classe (synthèse + table).
///
/// Émis par « Afficher les résultats » ou au changement de grande période.
/// [seuil] `null` ⇒ le backend applique 50 %.
class ResultatsClasseRequested extends ResultatsClasseEvent {
  final String classroomId;
  final String periodeScolaireId;
  final double? seuil;

  const ResultatsClasseRequested({
    required this.classroomId,
    required this.periodeScolaireId,
    this.seuil,
  });

  @override
  List<Object?> get props => [classroomId, periodeScolaireId, seuil];
}

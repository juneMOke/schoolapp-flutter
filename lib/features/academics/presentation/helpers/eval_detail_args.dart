import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';

/// Contexte d'affichage passé du détail d'un cours vers la page de saisie d'une
/// évaluation : l'évaluation elle-même (dérivée du détail déjà chargé, comme la
/// consultation des notes qui passe l'entête en argument) + de quoi peindre le
/// fil de retour et le rattachement.
///
/// L'`id` de [eval] alimente le chargement de la grille (`getNotesEleves`) et
/// [eval.maxPoints] la validation locale ; l'en-tête est rendu directement sans
/// requête supplémentaire (pas de `getEvaluationById` au contrat).
class EvalDetailArgs extends Equatable {
  final EvalVm eval;
  final String brancheNom;
  final String classroomName;

  /// Rattachement lisible « Période N · Sous-période M » (ou « … · Examen »).
  final String rattachementLabel;

  const EvalDetailArgs({
    required this.eval,
    required this.brancheNom,
    required this.classroomName,
    required this.rattachementLabel,
  });

  @override
  List<Object?> get props => [
    eval,
    brancheNom,
    classroomName,
    rattachementLabel,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';

/// Contexte d'affichage passé de la liste « Mes cours » vers la page détail :
/// l'identifiant du cours (pour charger la notation) et de quoi peindre l'en-tête
/// et le fil de retour avant l'arrivée des données.
class CoursDetailArgs extends Equatable {
  final String coursId;
  final String brancheNom;
  final String classroomName;
  final AcademicsClassVisual visual;

  const CoursDetailArgs({
    required this.coursId,
    required this.brancheNom,
    required this.classroomName,
    required this.visual,
  });

  @override
  List<Object?> get props => [coursId, brancheNom, classroomName, visual];
}

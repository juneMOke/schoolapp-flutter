import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';

/// Cours d'un enseignant regroupés par classe : le résumé de la classe et les
/// références (id + branche) des cours qu'il y enseigne.
class CourseSummary extends Equatable {
  final ClassroomSummary classroom;
  final List<CourseRef> courses;

  /// Vrai quand la classe n'est **pas encore** dans le cache local : on connaît
  /// les cours, pas la classe qui les porte — donc ni son nom, ni son année.
  ///
  /// Ces cours ne sont pas des cartes : l'écran les **masque** et se contente
  /// de dire qu'une classe n'est pas synchronisée. Les afficher donnerait des
  /// cartes anonymes aux effectifs à zéro ; les taire tout à fait laisserait
  /// croire à un cours perdu, alors qu'il n'attend que le pull des classes.
  final bool classroomUnsynced;

  const CourseSummary({
    required this.classroom,
    required this.courses,
    this.classroomUnsynced = false,
  });

  @override
  List<Object?> get props => [classroom, courses, classroomUnsynced];
}

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';

/// Cours d'un enseignant regroupés par classe : le résumé de la classe et les
/// références (id + branche) des cours qu'il y enseigne.
class CourseSummary extends Equatable {
  final ClassroomSummary classroom;
  final List<CourseRef> courses;

  const CourseSummary({required this.classroom, required this.courses});

  @override
  List<Object?> get props => [classroom, courses];
}

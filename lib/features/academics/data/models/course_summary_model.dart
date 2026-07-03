import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/data/models/classroom_summary_model.dart';
import 'package:school_app_flutter/features/academics/data/models/course_ref_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';

/// Modèle « mes cours » (résumé de classe + cours enseignés). Écrit à la main
/// (pas de `@JsonSerializable`) car `courses` accepte deux formes JSON via
/// [CourseRefModel.fromJson] (transition de contrat — cf. ce modèle).
class CourseSummaryModel extends Equatable {
  final ClassroomSummaryModel classroom;
  final List<CourseRefModel> courses;

  const CourseSummaryModel({required this.classroom, required this.courses});

  factory CourseSummaryModel.fromJson(Map<String, dynamic> json) =>
      CourseSummaryModel(
        classroom: ClassroomSummaryModel.fromJson(
          json['classroom'] as Map<String, dynamic>,
        ),
        courses: (json['courses'] as List<dynamic>? ?? const [])
            .map(CourseRefModel.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'classroom': classroom.toJson(),
    'courses': courses.map((c) => c.toJson()).toList(),
  };

  CourseSummary toEntity() => CourseSummary(
    classroom: classroom.toEntity(),
    courses: courses.map((c) => c.toEntity()).toList(),
  );

  @override
  List<Object?> get props => [classroom, courses];
}

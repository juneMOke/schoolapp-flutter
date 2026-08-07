import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_parent.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_student.dart';

/// Détail complet d'un dossier (inscription + élève + tuteurs + documents).
class LocalEnrollmentDetail extends Equatable {
  final LocalEnrollment enrollment;
  final LocalStudent student;
  final List<LocalParent> parents;
  final List<LocalGeneratedDocument> documents;

  const LocalEnrollmentDetail({
    required this.enrollment,
    required this.student,
    this.parents = const [],
    this.documents = const [],
  });

  @override
  List<Object?> get props => [enrollment, student, parents, documents];
}

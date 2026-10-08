import 'package:equatable/equatable.dart';

/// Un élève visé par un geste de désactivation : l'inscription de l'année,
/// l'élève et l'année qu'elle porte.
class SuspensionTarget extends Equatable {
  final String enrollmentId;
  final String studentId;
  final String academicYearId;

  const SuspensionTarget({
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [enrollmentId, studentId, academicYearId];
}

import 'package:equatable/equatable.dart';

/// Ce que le guichet demande : faire passer l'inscription [enrollmentId] du
/// niveau [fromSchoolLevelId] — celui qu'il voit — au niveau cible.
class LevelCorrectionRequest extends Equatable {
  final String enrollmentId;
  final String studentId;
  final String academicYearId;
  final String fromSchoolLevelId;
  final String toSchoolLevelId;
  final String toSchoolLevelGroupId;
  final String? toClassroomId;
  final String reason;

  const LevelCorrectionRequest({
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.fromSchoolLevelId,
    required this.toSchoolLevelId,
    required this.toSchoolLevelGroupId,
    required this.reason,
    this.toClassroomId,
  });

  @override
  List<Object?> get props => [
    enrollmentId,
    studentId,
    academicYearId,
    fromSchoolLevelId,
    toSchoolLevelId,
    toSchoolLevelGroupId,
    toClassroomId,
    reason,
  ];
}

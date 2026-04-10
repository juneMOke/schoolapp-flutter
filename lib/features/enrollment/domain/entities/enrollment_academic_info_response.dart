import 'package:equatable/equatable.dart';

class EnrollmentAcademicInfoResponse extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final String previousSchoolName;
  final String previousAcademicYear;
  final String previousSchoolLevelGroup;
  final String previousSchoolLevel;
  final double previousRate;
  final int? previousRank;
  final bool validatedPreviousYear;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String? transferReason;
  final String? cancellationReason;

  const EnrollmentAcademicInfoResponse({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.previousSchoolName,
    required this.previousAcademicYear,
    required this.previousSchoolLevelGroup,
    required this.previousSchoolLevel,
    required this.previousRate,
    this.previousRank,
    required this.validatedPreviousYear,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.transferReason,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousRate,
    previousRank,
    validatedPreviousYear,
    schoolLevelGroupId,
    schoolLevelId,
    transferReason,
    cancellationReason,
  ];
}

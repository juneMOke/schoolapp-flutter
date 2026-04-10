part of 'enrollment_academic_info_bloc.dart';

sealed class EnrollmentAcademicInfoEvent extends Equatable {
  const EnrollmentAcademicInfoEvent();

  @override
  List<Object?> get props => [];
}

class EnrollmentAcademicInfoStateReset extends EnrollmentAcademicInfoEvent {
  const EnrollmentAcademicInfoStateReset();
}

class EnrollmentAcademicInfoUpdateRequested
    extends EnrollmentAcademicInfoEvent {
  final String enrollmentId;
  final String academicYearId;
  final String previousSchoolName;
  final String previousAcademicYear;
  final String previousSchoolLevelGroup;
  final String previousSchoolLevel;
  final double previousRate;
  final int? previousRank;
  final bool validatedPreviousYear;
  final String? transferReason;
  final String? cancellationReason;
  final String schoolLevelId;
  final String schoolLevelGroupId;

  const EnrollmentAcademicInfoUpdateRequested({
    required this.enrollmentId,
    required this.academicYearId,
    required this.previousSchoolName,
    required this.previousAcademicYear,
    required this.previousSchoolLevelGroup,
    required this.previousSchoolLevel,
    required this.previousRate,
    this.previousRank,
    required this.validatedPreviousYear,
    this.transferReason,
    this.cancellationReason,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [
    enrollmentId,
    academicYearId,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousRate,
    previousRank,
    validatedPreviousYear,
    transferReason,
    cancellationReason,
    schoolLevelId,
    schoolLevelGroupId,
  ];
}

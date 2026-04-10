class UpdateEnrollmentAcademicInfoRequest {
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

  const UpdateEnrollmentAcademicInfoRequest({
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'academicYearId': academicYearId,
    'previousSchoolName': previousSchoolName,
    'previousAcademicYear': previousAcademicYear,
    'previousSchoolLevelGroup': previousSchoolLevelGroup,
    'previousSchoolLevel': previousSchoolLevel,
    'previousRate': previousRate,
    'previousRank': previousRank,
    'validatedPreviousYear': validatedPreviousYear,
    'transferReason': transferReason,
    'cancellationReason': cancellationReason,
    'schoolLevelId': schoolLevelId,
    'schoolLevelGroupId': schoolLevelGroupId,
  };
}

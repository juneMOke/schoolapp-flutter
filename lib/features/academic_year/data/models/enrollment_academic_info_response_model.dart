import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_academic_info_response.dart';

class EnrollmentAcademicInfoResponseModel {
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

  const EnrollmentAcademicInfoResponseModel({
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

  factory EnrollmentAcademicInfoResponseModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      EnrollmentAcademicInfoResponseModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        academicYearId: json['academicYearId'] as String,
        previousSchoolName: json['previousSchoolName'] as String,
        previousAcademicYear: json['previousAcademicYear'] as String,
        previousSchoolLevelGroup: json['previousSchoolLevelGroup'] as String,
        previousSchoolLevel: json['previousSchoolLevel'] as String,
        previousRate: (json['previousRate'] as num).toDouble(),
        previousRank: json['previousRank'] as int?,
        validatedPreviousYear: json['validatedPreviousYear'] as bool,
        schoolLevelGroupId: json['schoolLevelGroupId'] as String? ?? '',
        schoolLevelId: json['schoolLevelId'] as String? ?? '',
        transferReason: json['transferReason'] as String?,
        cancellationReason: json['cancellationReason'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studentId': studentId,
    'academicYearId': academicYearId,
    'previousSchoolName': previousSchoolName,
    'previousAcademicYear': previousAcademicYear,
    'previousSchoolLevelGroup': previousSchoolLevelGroup,
    'previousSchoolLevel': previousSchoolLevel,
    'previousRate': previousRate,
    'previousRank': previousRank,
    'validatedPreviousYear': validatedPreviousYear,
    'schoolLevelGroupId': schoolLevelGroupId,
    'schoolLevelId': schoolLevelId,
    'transferReason': transferReason,
    'cancellationReason': cancellationReason,
  };

  EnrollmentAcademicInfoResponse toEntity() =>
      EnrollmentAcademicInfoResponse(
        id: id,
        studentId: studentId,
        academicYearId: academicYearId,
        previousSchoolName: previousSchoolName,
        previousAcademicYear: previousAcademicYear,
        previousSchoolLevelGroup: previousSchoolLevelGroup,
        previousSchoolLevel: previousSchoolLevel,
        previousRate: previousRate,
        previousRank: previousRank,
        validatedPreviousYear: validatedPreviousYear,
        schoolLevelGroupId: schoolLevelGroupId,
        schoolLevelId: schoolLevelId,
        transferReason: transferReason,
        cancellationReason: cancellationReason,
      );
}

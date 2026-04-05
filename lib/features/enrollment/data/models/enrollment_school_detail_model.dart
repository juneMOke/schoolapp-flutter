import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

class EnrollmentSchoolDetailModel {
  final String id;
  final EnrollmentStatus status;
  final String academicYearId;
  final String enrollmentCode;
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

  const EnrollmentSchoolDetailModel({
    required this.id,
    required this.status,
    required this.academicYearId,
    required this.enrollmentCode,
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

  factory EnrollmentSchoolDetailModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentSchoolDetailModel(
        id: json['id'] as String,
        status: EnrollmentStatus.fromString(json['status'] as String),
        academicYearId: json['academicYearId'] as String,
        enrollmentCode: json['enrollmentCode'] as String,
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
    'status': status.name,
    'academicYearId': academicYearId,
    'enrollmentCode': enrollmentCode,
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

  EnrollmentSchoolDetail toEntity() => EnrollmentSchoolDetail(
    id: id,
    status: status,
    academicYearId: academicYearId,
    enrollmentCode: enrollmentCode,
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

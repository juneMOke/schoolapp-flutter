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
        id: _readString(json['id']),
        status: EnrollmentStatus.fromString(_readString(json['status'])),
        academicYearId: _readString(json['academicYearId']),
        enrollmentCode: _readString(json['enrollmentCode']),
        previousSchoolName: _readString(json['previousSchoolName']),
        previousAcademicYear: _readString(json['previousAcademicYear']),
        previousSchoolLevelGroup: _readString(json['previousSchoolLevelGroup']),
        previousSchoolLevel: _readString(json['previousSchoolLevel']),
        previousRate: _readDouble(json['previousRate']),
        previousRank: _readNullableInt(json['previousRank']),
        validatedPreviousYear: _readBool(json['validatedPreviousYear']),
        schoolLevelGroupId: _readString(json['schoolLevelGroupId']),
        schoolLevelId: _readString(json['schoolLevelId']),
        transferReason: _readString(json['transferReason']),
        cancellationReason: _readString(json['cancellationReason']),
      );

  static String _readString(dynamic value) => value?.toString() ?? '';

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }

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

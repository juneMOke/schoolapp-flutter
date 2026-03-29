import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

class EnrollmentDetailModel {
  final String enrollmentId;
  final String enrollmentCode;
  final String status;
  final String academicYearId;
  final String studentId;
  final String? levelId;
  final String? levelGroupId;
  final String? createdAt;
  final String? updatedAt;

  const EnrollmentDetailModel({
    required this.enrollmentId,
    required this.enrollmentCode,
    required this.status,
    required this.academicYearId,
    required this.studentId,
    this.levelId,
    this.levelGroupId,
    this.createdAt,
    this.updatedAt,
  });

  factory EnrollmentDetailModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentDetailModel(
        enrollmentId: json['enrollmentId'] as String,
        enrollmentCode: json['enrollmentCode'] as String,
        status: json['status'] as String,
        academicYearId: json['academicYearId'] as String,
        studentId: json['studentId'] as String,
        levelId: json['levelId'] as String?,
        levelGroupId: json['levelGroupId'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enrollmentId': enrollmentId,
    'enrollmentCode': enrollmentCode,
    'status': status,
    'academicYearId': academicYearId,
    'studentId': studentId,
    'levelId': levelId,
    'levelGroupId': levelGroupId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  EnrollmentDetail toEnrollmentDetail() => EnrollmentDetail(
    enrollmentId: enrollmentId,
    enrollmentCode: enrollmentCode,
    status: EnrollmentStatus.fromString(status),
    academicYearId: academicYearId,
    studentId: studentId,
    levelId: levelId,
    levelGroupId: levelGroupId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

class EnrollmentDetail extends Equatable {
  final String enrollmentId;
  final String enrollmentCode;
  final EnrollmentStatus status;
  final String academicYearId;
  final String studentId;
  final String? levelId;
  final String? levelGroupId;
  final String? createdAt;
  final String? updatedAt;

  const EnrollmentDetail({
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

  @override
  List<Object?> get props => [
    enrollmentId,
    enrollmentCode,
    status,
    academicYearId,
    studentId,
    levelId,
    levelGroupId,
    createdAt,
    updatedAt,
  ];
}

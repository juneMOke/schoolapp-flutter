import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class EnrollmentSummary extends Equatable {
  final String enrollmentId;
  final String enrollmentCode;
  final String status;
  final StudentSummary student;

  const EnrollmentSummary({
    required this.enrollmentId,
    required this.enrollmentCode,
    required this.status,
    required this.student,
  });

  @override
  List<Object?> get props => [enrollmentId, enrollmentCode, status, student];
}

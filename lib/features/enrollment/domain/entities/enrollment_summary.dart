import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class EnrollmentSummary {
  final String enrollmentId;
  final String enrollmentCode;
  final String status;
  final StudentSummary student;

  EnrollmentSummary({
    required this.enrollmentId,
    required this.enrollmentCode,
    required this.status,
    required this.student,
  });
}

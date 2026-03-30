import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class EnrollmentSummary {
  final String id;
  final String enrollmentCode;
  final String status;
  final List<StudentSummary> students;

  EnrollmentSummary({
    required this.id,
    required this.enrollmentCode,
    required this.status,
    required this.students,
  });
}

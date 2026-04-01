import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/student/data/models/student_summary_model.dart';

class EnrollmentSummaryModel {
  final String enrollmentId;
  final String enrollmentCode;
  final String status;
  final StudentSummaryModel student;

  EnrollmentSummaryModel({
    required this.enrollmentId,
    required this.enrollmentCode,
    required this.status,
    required this.student,
  });

  factory EnrollmentSummaryModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentSummaryModel(
        enrollmentId: json['enrollmentId'] as String,
        enrollmentCode: json['enrollmentCode'] as String,
        status: json['status'] as String,
        student: StudentSummaryModel.fromJson(
          json['studentSummaryDto'] as Map<String, dynamic>,
        ),
      );

  EnrollmentSummary toEnrollmentSummary() => EnrollmentSummary(
    enrollmentId: enrollmentId,
    enrollmentCode: enrollmentCode,
    status: status,
    student: this.student.toStudentSummary(),
  );
}

import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/student/data/models/student_summary_model.dart';

class EnrollmentSummaryModel {
  final String id;
  final String enrollmentCode;
  final String status;
  final List<StudentSummaryModel> students;

  EnrollmentSummaryModel({
    required this.id,
    required this.enrollmentCode,
    required this.status,
    required this.students,
  });

  factory EnrollmentSummaryModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentSummaryModel(
        id: json['id'] as String,
        enrollmentCode: json['enrollmentCode'] as String,
        status: json['status'] as String,
        students: (json['students'] as List<dynamic>)
            .map(
              (student) =>
                  StudentSummaryModel.fromJson(student as Map<String, dynamic>),
            )
            .toList(),
      );

  EnrollmentSummary toEnrollmentSummary() => EnrollmentSummary(
    id: id,
    enrollmentCode: enrollmentCode,
    status: status,
    students: students.map((student) => student.toStudentSummary()).toList(),
  );
}

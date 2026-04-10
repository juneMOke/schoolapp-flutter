import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

class EnrollmentDetail {
  final StudentDetail studentDetail;
  final List<ParentSummary> parentDetails;
  final EnrollmentSchoolDetail enrollmentDetail;

  EnrollmentDetail({
    required this.studentDetail,
    required this.parentDetails,
    required this.enrollmentDetail,
  });
}

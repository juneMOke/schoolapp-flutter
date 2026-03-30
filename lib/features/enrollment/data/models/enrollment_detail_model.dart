import 'package:school_app_flutter/features/enrollment/data/models/enrollment_school_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/student/data/models/parent_summary_model.dart';
import 'package:school_app_flutter/features/student/data/models/student_detail_model.dart';

class EnrollmentDetailModel {
  final StudentDetailModel studentDetail;
  final ParentSummaryModel parentDetails;
  final EnrollmentSchoolDetailModel enrollmentDetail;

  EnrollmentDetailModel({
    required this.studentDetail,
    required this.parentDetails,
    required this.enrollmentDetail,
  });

  factory EnrollmentDetailModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentDetailModel(
        studentDetail: StudentDetailModel.fromJson(
          json['studentDetail'] as Map<String, dynamic>,
        ),
        parentDetails: ParentSummaryModel.fromJson(
          json['parentDetails'] as Map<String, dynamic>,
        ),
        enrollmentDetail: EnrollmentSchoolDetailModel.fromJson(
          json['enrollmentDetail'] as Map<String, dynamic>,
        ),
      );

  EnrollmentDetail toEnrollmentDetail() {
    return EnrollmentDetail(
      studentDetail: studentDetail.toStudentDetail(),
      parentDetails: parentDetails.toParentSummary(),
      enrollmentDetail: enrollmentDetail.toEntity(),
    );
  }
}

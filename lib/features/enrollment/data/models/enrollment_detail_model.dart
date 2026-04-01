import 'package:school_app_flutter/features/enrollment/data/models/enrollment_school_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/student/data/models/parent_summary_model.dart';
import 'package:school_app_flutter/features/student/data/models/student_detail_model.dart';

class EnrollmentDetailModel {
  final StudentDetailModel studentDetail;
  final List<ParentSummaryModel> parentDetails;
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
        parentDetails: (json['parentDetails'] as List<dynamic>)
            .map((e) => ParentSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        enrollmentDetail: EnrollmentSchoolDetailModel.fromJson(
          json['enrollmentDetail'] as Map<String, dynamic>,
        ),
      );

  EnrollmentDetail toEnrollmentDetail() {
    return EnrollmentDetail(
      studentDetail: studentDetail.toStudentDetail(),
      parentDetails: parentDetails.map((e) => e.toParentSummary()).toList(),
      enrollmentDetail: enrollmentDetail.toEntity(),
    );
  }
}

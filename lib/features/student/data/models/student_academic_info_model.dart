import 'package:school_app_flutter/features/student/domain/entities/student_academic_info.dart';

class StudentAcademicInfoModel {
  final String studentId;
  final String schoolLevelId;
  final String schoolLevelGroupId;

  const StudentAcademicInfoModel({
    required this.studentId,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  factory StudentAcademicInfoModel.fromJson(Map<String, dynamic> json) {
    return StudentAcademicInfoModel(
      studentId: json['studentId'] as String? ?? '',
      schoolLevelId: json['schoolLevelId'] as String? ?? '',
      schoolLevelGroupId: json['schoolLevelGroupId'] as String? ?? '',
    );
  }

  StudentAcademicInfo toEntity() {
    return StudentAcademicInfo(
      studentId: studentId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    );
  }
}

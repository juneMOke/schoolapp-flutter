class UpdateStudentAcademicInfoRequest {
  final String schoolLevelId;
  final String schoolLevelGroupId;

  const UpdateStudentAcademicInfoRequest({
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schoolLevelId': schoolLevelId,
    'schoolLevelGroupId': schoolLevelGroupId,
  };
}

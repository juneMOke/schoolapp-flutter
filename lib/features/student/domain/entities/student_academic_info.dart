import 'package:equatable/equatable.dart';

class StudentAcademicInfo extends Equatable {
  final String studentId;
  final String schoolLevelId;
  final String schoolLevelGroupId;

  const StudentAcademicInfo({
    required this.studentId,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => <Object?>[
    studentId,
    schoolLevelId,
    schoolLevelGroupId,
  ];
}

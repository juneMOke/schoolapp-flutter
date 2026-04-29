import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';

class ClassesOrganisationLevelOption extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;
  final bool splitIntoClassrooms;
  final List<BootstrapClassroom> classrooms;

  const ClassesOrganisationLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
    required this.splitIntoClassrooms,
    required this.classrooms,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';

  ClassesOrganisationLevelOption copyWith({
    String? schoolLevelGroupId,
    String? schoolLevelId,
    String? label,
    bool? splitIntoClassrooms,
    List<BootstrapClassroom>? classrooms,
  }) => ClassesOrganisationLevelOption(
    schoolLevelGroupId: schoolLevelGroupId ?? this.schoolLevelGroupId,
    schoolLevelId: schoolLevelId ?? this.schoolLevelId,
    label: label ?? this.label,
    splitIntoClassrooms: splitIntoClassrooms ?? this.splitIntoClassrooms,
    classrooms: classrooms ?? this.classrooms,
  );

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    label,
    splitIntoClassrooms,
    classrooms,
  ];
}

class ClassesOrganisationSearchRequest extends Equatable {
  final String firstName;
  final String lastName;
  final String surname;
  final ClassesOrganisationLevelOption? selectedLevel;

  const ClassesOrganisationSearchRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.selectedLevel,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    surname,
    selectedLevel,
  ];
}

class ClassroomMemberReassignIntent extends Equatable {
  final String classroomId;
  final String classroomMemberId;
  final String studentDisplayName;

  const ClassroomMemberReassignIntent({
    required this.classroomId,
    required this.classroomMemberId,
    required this.studentDisplayName,
  });

  @override
  List<Object?> get props => [
    classroomId,
    classroomMemberId,
    studentDisplayName,
  ];
}

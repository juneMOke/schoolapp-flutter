import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';

class ClassesOrganisationCycleOption extends Equatable {
  final String id;
  final String label;
  final List<ClassesOrganisationLevelOption> levels;

  const ClassesOrganisationCycleOption({
    required this.id,
    required this.label,
    required this.levels,
  });

  @override
  List<Object?> get props => [id, label, levels];
}

class ClassesOrganisationLevelOption extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelGroupName;
  final String schoolLevelId;
  final String schoolLevelName;
  final bool splitIntoClassrooms;
  final List<BootstrapClassroom> classrooms;

  const ClassesOrganisationLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelGroupName,
    required this.schoolLevelId,
    required this.schoolLevelName,
    required this.splitIntoClassrooms,
    required this.classrooms,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';

  ClassesOrganisationLevelOption copyWith({
    String? schoolLevelGroupId,
    String? schoolLevelGroupName,
    String? schoolLevelId,
    String? schoolLevelName,
    bool? splitIntoClassrooms,
    List<BootstrapClassroom>? classrooms,
  }) => ClassesOrganisationLevelOption(
    schoolLevelGroupId: schoolLevelGroupId ?? this.schoolLevelGroupId,
    schoolLevelGroupName: schoolLevelGroupName ?? this.schoolLevelGroupName,
    schoolLevelId: schoolLevelId ?? this.schoolLevelId,
    schoolLevelName: schoolLevelName ?? this.schoolLevelName,
    splitIntoClassrooms: splitIntoClassrooms ?? this.splitIntoClassrooms,
    classrooms: classrooms ?? this.classrooms,
  );

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelGroupName,
    schoolLevelId,
    schoolLevelName,
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
  final String? classroomId;
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

class ClassroomReassignOption extends Equatable {
  final String id;
  final String name;
  final int totalCount;

  const ClassroomReassignOption({
    required this.id,
    required this.name,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [id, name, totalCount];
}

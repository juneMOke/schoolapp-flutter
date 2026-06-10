import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

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
  List<Object?> get props => [firstName, lastName, surname, selectedLevel];
}

class ClassroomMemberReassignIntent extends Equatable {
  /// Classe d'origine de l'élève. `null` → élève non réparti (mode affectation).
  final String? classroomId;
  final String classroomMemberId;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final ClassroomMemberGender studentGender;
  final String studentDisplayName;

  const ClassroomMemberReassignIntent({
    required this.classroomId,
    required this.classroomMemberId,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    required this.studentGender,
    required this.studentDisplayName,
  });

  @override
  List<Object?> get props => [
    classroomId,
    classroomMemberId,
    studentId,
    studentFirstName,
    studentLastName,
    studentGender,
    studentDisplayName,
  ];
}

class ClassroomReassignOption extends Equatable {
  final String id;
  final String name;
  final int totalCount;
  final int capacity;
  final int femaleCount;
  final int maleCount;

  const ClassroomReassignOption({
    required this.id,
    required this.name,
    required this.totalCount,
    required this.capacity,
    required this.femaleCount,
    required this.maleCount,
  });

  bool get isFull => capacity > 0 && totalCount >= capacity;

  @override
  List<Object?> get props => [
    id,
    name,
    totalCount,
    capacity,
    femaleCount,
    maleCount,
  ];
}

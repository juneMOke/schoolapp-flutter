import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';

class ClassesListCycleOption extends Equatable {
  final String id;
  final String label;
  final int displayOrder;
  final List<ClassesListLevelOption> levels;

  const ClassesListCycleOption({
    required this.id,
    required this.label,
    required this.displayOrder,
    required this.levels,
  });

  @override
  List<Object?> get props => [id, label, displayOrder, levels];
}

class ClassesListLevelOption extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelGroupName;
  final String schoolLevelId;
  final String label;
  final int displayOrder;
  final bool splitIntoClassrooms;
  final List<BootstrapClassroom> classrooms;

  const ClassesListLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelGroupName,
    required this.schoolLevelId,
    required this.label,
    required this.displayOrder,
    required this.splitIntoClassrooms,
    required this.classrooms,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelGroupName,
    schoolLevelId,
    label,
    displayOrder,
    splitIntoClassrooms,
    classrooms,
  ];
}

class ClassesListSearchRequest extends Equatable {
  final String firstName;
  final String lastName;
  final String surname;
  final ClassesListCycleOption? selectedCycle;
  final ClassesListLevelOption? selectedLevel;
  final BootstrapClassroom? selectedClassroom;

  const ClassesListSearchRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.selectedCycle,
    required this.selectedLevel,
    required this.selectedClassroom,
  });

  bool get hasNameFilters =>
      firstName.trim().isNotEmpty ||
      lastName.trim().isNotEmpty ||
      surname.trim().isNotEmpty;

  bool get targetsClassroom => selectedClassroom != null;

  bool get hasAcademicFilters =>
      selectedCycle != null ||
      selectedLevel != null ||
      selectedClassroom != null;

  bool get hasAnyCriteria => hasNameFilters || hasAcademicFilters;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    surname,
    selectedCycle,
    selectedLevel,
    selectedClassroom,
  ];
}

class ClassesListStudentRow extends Equatable {
  final String id;

  /// Identifiant stable de l'élève (≠ [id] qui peut être un id d'adhésion).
  /// Sert de clé à la teinte d'identité de l'avatar.
  final String studentId;
  final String lastName;
  final String surname;
  final String firstName;
  final String classroomLabel;

  const ClassesListStudentRow({
    required this.id,
    required this.studentId,
    required this.lastName,
    required this.surname,
    required this.firstName,
    this.classroomLabel = '',
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    lastName,
    surname,
    firstName,
    classroomLabel,
  ];
}

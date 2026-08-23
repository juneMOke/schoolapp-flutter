import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';

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
  final List<OfflineClassroom> classrooms;

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

/// Critères émis par la carte de recherche de la liste des classes.
///
/// Les deux modes s'excluent, et le [mode] est porté ici plutôt que déduit des
/// champs remplis : sans lui, un affinage par nom en mode « Par classe » serait
/// indiscernable d'une recherche par identité dont le cycle serait resté vide.
class ClassesListSearchRequest extends Equatable {
  final SearchMode mode;

  /// Mode identité : le prénom saisi. Mode classe : toujours vide.
  final String firstName;

  /// Mode identité : le nom saisi. Mode classe : le **nom d'affinage**, qui
  /// n'ouvre pas la recherche mais restreint la classe déjà ouverte.
  final String lastName;

  /// Mode identité : le post-nom saisi. Mode classe : toujours vide.
  final String surname;

  final ClassesListCycleOption? selectedCycle;
  final ClassesListLevelOption? selectedLevel;
  final OfflineClassroom? selectedClassroom;

  const ClassesListSearchRequest({
    required this.mode,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.selectedCycle,
    required this.selectedLevel,
    required this.selectedClassroom,
  });

  bool get isIdentityMode => mode == SearchMode.identity;

  bool get hasNameFilters =>
      firstName.trim().isNotEmpty ||
      lastName.trim().isNotEmpty ||
      surname.trim().isNotEmpty;

  /// Vrai quand les résultats doivent venir du **roster local d'une classe**
  /// plutôt que de la liste des inscriptions. Le mode identité ne cible jamais
  /// une classe, même si une classe traîne dans les critères de l'autre mode.
  bool get targetsClassroom =>
      mode == SearchMode.level && selectedClassroom != null;

  bool get hasAcademicFilters =>
      selectedCycle != null ||
      selectedLevel != null ||
      selectedClassroom != null;

  /// Ce qui arme la recherche, par mode : un niveau d'un côté, les trois noms
  /// de l'autre. L'affinage par nom du mode classe n'arme rien.
  bool get hasAnyCriteria => switch (mode) {
    SearchMode.level => selectedLevel != null,
    SearchMode.identity =>
      firstName.trim().isNotEmpty &&
          lastName.trim().isNotEmpty &&
          surname.trim().isNotEmpty,
  };

  @override
  List<Object?> get props => [
    mode,
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

  /// Niveau de l'élève, tel que la LIGNE le porte — vide quand la source ne
  /// sait pas le dire (roster d'une classe, ou référentiel pas encore
  /// descendu). N'est rendu qu'en mode identité : ailleurs le niveau est le
  /// critère, déjà annoncé au-dessus du tableau.
  final String levelLabel;

  const ClassesListStudentRow({
    required this.id,
    required this.studentId,
    required this.lastName,
    required this.surname,
    required this.firstName,
    this.classroomLabel = '',
    this.levelLabel = '',
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    lastName,
    surname,
    firstName,
    classroomLabel,
    levelLabel,
  ];
}

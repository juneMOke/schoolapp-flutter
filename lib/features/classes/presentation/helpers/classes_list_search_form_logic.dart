import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';

class ClassesListSearchFormLogic {
  const ClassesListSearchFormLogic._();

  static ClassesListSelectionSync computeSelectionSync({
    required List<ClassesListCycleOption> options,
    required String? selectedCycleId,
    required String? selectedLevelKey,
    required String? selectedClassroomId,
  }) {
    final selectedCycle = findCycle(options, selectedCycleId);
    if (selectedCycleId != null && selectedCycle == null) {
      return const ClassesListSelectionSync(
        clearCycle: true,
        clearLevel: true,
        clearClassroom: true,
      );
    }

    final levelOptions = selectedCycle?.levels ?? const <ClassesListLevelOption>[];
    final selectedLevel = findLevel(levelOptions, selectedLevelKey);
    if (selectedLevelKey != null && selectedLevel == null) {
      return const ClassesListSelectionSync(clearLevel: true, clearClassroom: true);
    }

    final selectedClassroom =
        findClassroom(selectedLevel?.classrooms ?? const [], selectedClassroomId);
    if (selectedClassroomId != null && selectedClassroom == null) {
      return const ClassesListSelectionSync(clearClassroom: true);
    }

    return const ClassesListSelectionSync();
  }

  static ClassesListCycleOption? findCycle(
    List<ClassesListCycleOption> options,
    String? cycleId,
  ) {
    if (cycleId == null) {
      return null;
    }
    for (final option in options) {
      if (option.id == cycleId) {
        return option;
      }
    }
    return null;
  }

  static ClassesListLevelOption? findLevel(
    List<ClassesListLevelOption> options,
    String? levelKey,
  ) {
    if (levelKey == null) {
      return null;
    }
    for (final option in options) {
      if (option.key == levelKey) {
        return option;
      }
    }
    return null;
  }

  static BootstrapClassroom? findClassroom(
    List<BootstrapClassroom> options,
    String? classroomId,
  ) {
    if (classroomId == null) {
      return null;
    }
    for (final classroom in options) {
      if (classroom.id == classroomId) {
        return classroom;
      }
    }
    return null;
  }

  /// Le bouton Rechercher est actif si et seulement si :
  /// - le cycle ET le niveau sont sélectionnés (condition minimale obligatoire)
  ///
  /// En plus de cette base, classroom et/ou un nom peuvent être ajoutés sans
  /// modifier la règle d'activation (ils affinent la recherche, pas l'activent).
  static bool hasAtLeastOneCriterion({
    required ClassesListCycleOption? selectedCycle,
    required ClassesListLevelOption? selectedLevel,
    required String? selectedClassroomId,
    required String firstName,
    required String lastName,
    required String surname,
  }) {
    // Cycle + niveau sont requis dans tous les cas
    return selectedCycle != null && selectedLevel != null;
  }
}

class ClassesListSelectionSync {
  final bool clearCycle;
  final bool clearLevel;
  final bool clearClassroom;

  const ClassesListSelectionSync({
    this.clearCycle = false,
    this.clearLevel = false,
    this.clearClassroom = false,
  });

  bool get hasAny => clearCycle || clearLevel || clearClassroom;
}

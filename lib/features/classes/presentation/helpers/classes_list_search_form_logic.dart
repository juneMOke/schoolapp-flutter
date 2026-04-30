import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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

  static String? validationMessage({
    required AppLocalizations l10n,
    required ClassesListCycleOption? selectedCycle,
    required ClassesListLevelOption? selectedLevel,
    required String firstName,
    required String lastName,
    required String surname,
  }) {
    if (selectedCycle == null || selectedLevel == null) {
      return l10n.classesListSearchValidationLevelRequired;
    }

    final values = [firstName, lastName, surname].map((value) => value.trim());
    final hasAny = values.any((value) => value.isNotEmpty);
    final hasAll = values.every((value) => value.isNotEmpty);

    if (hasAny && !hasAll) {
      return l10n.classesListSearchValidationNamesIncomplete;
    }

    return null;
  }

  static String classroomHelper({
    required AppLocalizations l10n,
    required ClassesListCycleOption? selectedCycle,
    required ClassesListLevelOption? selectedLevel,
    required List<BootstrapClassroom> classroomOptions,
  }) {
    if (selectedCycle == null) {
      return l10n.classesListClassroomHelpSelectCycle;
    }
    if (selectedLevel == null) {
      return l10n.classesListClassroomHelpSelectLevel;
    }
    if (!selectedLevel.splitIntoClassrooms) {
      return l10n.classesListClassroomHelpLevelNotSplit;
    }
    if (classroomOptions.isEmpty) {
      return l10n.classesOrganisationNoClassrooms;
    }
    return l10n.classesListClassroomHelpOptional;
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

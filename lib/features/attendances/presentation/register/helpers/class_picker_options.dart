import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

/// Un niveau et ses classes, dans le sélecteur de classe.
class ClassPickerLevel extends Equatable {
  final String id;
  final String label;
  final List<OfflineClassroom> classrooms;

  const ClassPickerLevel({
    required this.id,
    required this.label,
    required this.classrooms,
  });

  ClassPresenceClassroom classroomOf(OfflineClassroom classroom) =>
      ClassPresenceClassroom(
        id: classroom.id,
        name: classroom.name,
        levelName: label,
        studentCount: classroom.totalCount,
      );

  @override
  List<Object?> get props => [id, label, classrooms];
}

/// Un cycle (primaire, secondaire…) et ses niveaux.
class ClassPickerCycle extends Equatable {
  final String id;
  final String label;
  final List<ClassPickerLevel> levels;

  const ClassPickerCycle({
    required this.id,
    required this.label,
    required this.levels,
  });

  bool contains(String classroomId) => levels.any(
    (level) => level.classrooms.any((classroom) => classroom.id == classroomId),
  );

  @override
  List<Object?> get props => [id, label, levels];
}

/// Les cycles de l'année, dans l'ordre du référentiel, chacun avec ses
/// niveaux et leurs classes. Un cycle sans classe n'est pas proposé.
List<ClassPickerCycle> buildClassPickerCycles(
  List<SchoolLevelGroupBundle> bundles,
  List<OfflineClassroom> classrooms,
) {
  final byLevel = <String, List<OfflineClassroom>>{};
  for (final classroom in classrooms) {
    final levelId = classroom.schoolLevelId;
    if (levelId == null) continue;
    (byLevel[levelId] ??= []).add(classroom);
  }
  final cycles = SortedNestedOptionsHelper.build(
    outers: bundles,
    outerOrder: (bundle) => bundle.group.displayOrder,
    inners: (bundle) => bundle.levels,
    innerOrder: (level) => level.displayOrder,
    mapInner: (bundle, level) => ClassPickerLevel(
      id: level.id,
      label: level.name,
      classrooms: byLevel[level.id] ?? const [],
    ),
    mapOuter: (bundle, levels) => ClassPickerCycle(
      id: bundle.group.id,
      label: bundle.group.name,
      levels: [
        for (final level in levels)
          if (level.classrooms.isNotEmpty) level,
      ],
    ),
  );
  return [
    for (final cycle in cycles)
      if (cycle.levels.isNotEmpty) cycle,
  ];
}

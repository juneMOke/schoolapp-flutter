import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_picker_options.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

void main() {
  SchoolLevel level(String id, int order) => SchoolLevel(
    id: id,
    name: 'Niveau $id',
    code: id.toUpperCase(),
    displayOrder: order,
    splitIntoClassrooms: true,
  );

  SchoolLevelGroupBundle cycle(
    String id,
    int order,
    List<SchoolLevel> levels,
  ) => SchoolLevelGroupBundle(
    group: SchoolLevelGroup(
      id: id,
      name: 'Cycle $id',
      code: id.toUpperCase(),
      displayOrder: order,
    ),
    levels: levels,
  );

  OfflineClassroom classroom(String id, String? levelId) => OfflineClassroom(
    id: id,
    academicYearId: 'y1',
    schoolLevelId: levelId,
    name: 'Classe $id',
    totalCount: 3,
  );

  final bundles = [
    // Ordre du référentiel inverse de l'ordre de la liste.
    cycle('sec', 2, [level('s1', 1)]),
    cycle('pri', 1, [level('p6', 6), level('p1', 1), level('p3', 3)]),
    cycle('mat', 0, [level('m1', 1)]),
  ];

  test('cycles et niveaux dans l ordre du référentiel', () {
    final cycles = buildClassPickerCycles(bundles, [
      classroom('c6', 'p6'),
      classroom('c1', 'p1'),
      classroom('cs', 's1'),
    ]);

    expect(cycles.map((c) => c.id), ['pri', 'sec']);
    expect(cycles.first.levels.map((l) => l.id), ['p1', 'p6']);
  });

  test('un niveau ou un cycle sans classe n est pas proposé', () {
    final cycles = buildClassPickerCycles(bundles, [classroom('c1', 'p1')]);

    expect(cycles.map((c) => c.id), ['pri']);
    expect(cycles.single.levels.map((l) => l.id), ['p1']);
  });

  test('une classe sans niveau est ignorée', () {
    final cycles = buildClassPickerCycles(bundles, [
      classroom('orpheline', null),
    ]);

    expect(cycles, isEmpty);
  });

  test('la classe choisie porte le libellé de son niveau', () {
    final level = buildClassPickerCycles(bundles, [
      classroom('c1', 'p1'),
    ]).single.levels.single;

    final picked = level.classroomOf(level.classrooms.single);
    expect(picked.levelName, 'Niveau p1');
    expect(picked.studentCount, 3);
  });
}

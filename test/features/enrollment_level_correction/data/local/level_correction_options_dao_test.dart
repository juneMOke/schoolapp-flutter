import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_options_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../level_correction_fixtures.dart';

void main() {
  late Database db;
  late LevelCorrectionOptionsDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = LevelCorrectionOptionsDao(db);
    for (final (id, name, level, year) in const [
      ('cls-p2b', 'P2 B', 'lvl-p2', kYear),
      ('cls-p2a', 'P2 A', 'lvl-p2', kYear),
      ('cls-m2a', 'M2 A', 'lvl-m2', kYear),
      ('cls-old', 'P2 A', 'lvl-p2', 'year-0'),
    ]) {
      await db.insert('ref_classrooms', {
        'id': id,
        'name': name,
        'school_level_id': level,
        'academic_year_id': year,
      });
    }
  });
  tearDown(() => db.close());

  Future<void> member(String classroomId, {String status = 'ACTIVE'}) =>
      db.insert('ref_classroom_members', {
        'id': 'm-1',
        'student_id': kStudent,
        'classroom_id': classroomId,
        'academic_year_id': kYear,
        'status': status,
        'student_first_name': 'A',
        'student_last_name': 'B',
      });

  test("les classes de l'année seulement, triées par nom", () async {
    final options = await dao.classrooms(
      studentId: kStudent,
      academicYearId: kYear,
    );
    expect(options.classrooms.map((c) => c.id), [
      'cls-m2a',
      'cls-p2a',
      'cls-p2b',
    ]);
    expect(options.ofLevel('lvl-p2').map((c) => c.id), ['cls-p2a', 'cls-p2b']);
  });

  test("élève sans classe : rien n'est exigé", () async {
    final options = await dao.classrooms(
      studentId: kStudent,
      academicYearId: kYear,
    );
    expect(options.isInClassroom, isFalse);
    expect(options.requiresClassroom('lvl-p2'), isFalse);
  });

  test(
    'élève en classe : la classe actuelle est lue, et D3 s\'applique',
    () async {
      await member('cls-m2a');
      final options = await dao.classrooms(
        studentId: kStudent,
        academicYearId: kYear,
      );
      expect(options.currentClassroomId, 'cls-m2a');
      expect(options.requiresClassroom('lvl-p2'), isTrue);
      expect(options.requiresClassroom('lvl-p3'), isFalse);
    },
  );

  test("élève sorti de sa classe (INACTIVE, sans désactivation) : il n'est "
      "plus en classe, rien n'est exigé", () async {
    await member('cls-m2a', status: 'INACTIVE');
    final options = await dao.classrooms(
      studentId: kStudent,
      academicYearId: kYear,
    );
    expect(options.currentClassroomId, isNull);
    expect(options.requiresClassroom('lvl-p2'), isFalse);
  });

  test('élève désactivé : il garde sa classe, D3 s\'applique', () async {
    await member('cls-m2a', status: 'INACTIVE');
    await db.insert('enrollment_suspensions', {
      'id': 'sus-1',
      'school_id': kSchool,
      'enrollment_id': kEnrollment,
      'student_id': kStudent,
      'academic_year_id': kYear,
      'suspended_at': '2026-11-01T08:00:00Z',
      'updated_at': 1,
    });
    final options = await dao.classrooms(
      studentId: kStudent,
      academicYearId: kYear,
    );
    expect(options.currentClassroomId, 'cls-m2a');
    expect(options.requiresClassroom('lvl-p2'), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/projections/enrollment_suspension_sql.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../features/enrollment_suspension/suspension_fixtures.dart';
import '../../../features/offline_full_db.dart';

void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  Future<void> period(String student, {String? reactivatedAt}) =>
      db.insert('enrollment_suspensions', {
        'id': 'p-$student-${reactivatedAt ?? 'open'}',
        'school_id': kSchool,
        'enrollment_id': enrollmentOf(student),
        'student_id': student,
        'academic_year_id': kYear,
        'suspended_at': '2026-10-08T08:00:00Z',
        'reactivated_at': reactivatedAt,
        'reactivation_id': reactivatedAt == null ? null : 'r-$student',
        'reactivated_by': reactivatedAt == null ? null : kAuthor,
        'updated_at': 1,
      });

  /// Un élève transféré de A vers B : la ligne A reste, `INACTIVE`, comme
  /// historique ; B est son appartenance courante.
  Future<void> transferred(String student) async {
    await insertMember(
      db,
      student,
      status: 'INACTIVE',
      classroomId: 'class-A',
      id: 'm-$student-A',
    );
    await insertMember(db, student, classroomId: 'class-B', id: 'm-$student-B');
    await db.insert('classroom_transfers', {
      'id': 't-$student',
      'student_id': student,
      'from_classroom_id': 'class-A',
      'to_classroom_id': 'class-B',
      'school_level_id': 'lvl',
      'academic_year_id': kYear,
      'transferred_at': 1,
      'sync_status': 'SYNCED',
    });
  }

  test('project : INACTIVE si ouverte, ACTIVE sinon', () async {
    await insertMember(db, 's1');
    await insertMember(db, 's2', status: 'INACTIVE');
    await period('s1');

    await EnrollmentSuspensionSql.project(db, [('s1', kYear), ('s2', kYear)]);

    expect(await memberStatus(db, 's1'), 'INACTIVE');
    expect(await memberStatus(db, 's2'), 'ACTIVE');
  });

  test('project ne touche pas les membres d\'une autre année', () async {
    await insertMember(db, 's1');
    await insertMember(db, 's1', year: 'year-0', status: 'INACTIVE');
    await period('s1');

    await EnrollmentSuspensionSql.project(db, [('s1', kYear)]);

    expect(await memberStatus(db, 's1'), 'INACTIVE');
    expect(await memberStatus(db, 's1', year: 'year-0'), 'INACTIVE');
  });

  test('élève transféré : seule la classe courante bouge, la classe quittée '
      'reste INACTIVE', () async {
    await transferred('s1');
    Future<String?> statusIn(String classroom) async =>
        (await db.query(
              'ref_classroom_members',
              columns: ['status'],
              where: 'student_id = ? AND classroom_id = ?',
              whereArgs: ['s1', classroom],
            )).single['status']
            as String?;

    await period('s1');
    await EnrollmentSuspensionSql.project(db, [('s1', kYear)]);
    expect(await statusIn('class-A'), 'INACTIVE');
    expect(await statusIn('class-B'), 'INACTIVE');

    await db.delete('enrollment_suspensions');
    await EnrollmentSuspensionSql.project(db, [('s1', kYear)]);
    expect(await statusIn('class-A'), 'INACTIVE');
    expect(await statusIn('class-B'), 'ACTIVE');
  });

  test(
    'après un pull de membres : seul un geste en file reprend la main',
    () async {
      await insertMember(db, 's1', status: 'INACTIVE');
      await insertMember(db, 's2');
      // s1 : période synchronisée et fermée, le serveur dit INACTIVE → on garde.
      await period('s1', reactivatedAt: '2026-10-09T08:00:00Z');
      // s2 : désactivé hors ligne, pas encore envoyé.
      await EnrollmentSuspensionWriteDao(
        db,
      ).suspend([suspendGesture('s2')], schoolId: kSchool, nowMs: 1);
      await db.update('ref_classroom_members', {
        'status': 'ACTIVE',
      }, where: "student_id = 's2'");

      await EnrollmentSuspensionSql.reapplyAfterMemberPull(db, ['s1', 's2']);

      expect(await memberStatus(db, 's1'), 'INACTIVE');
      expect(await memberStatus(db, 's2'), 'INACTIVE');
    },
  );

  test('les prédicats filtrent une liste d\'inscriptions', () async {
    await period('s1');
    final rows = await db.rawQuery(
      "SELECT 1 FROM (SELECT 'enr-s1' AS id UNION SELECT 'enr-s2') e "
      'WHERE ${EnrollmentSuspensionSql.notSuspended('e.id')}',
    );
    expect(rows, hasLength(1));
  });
}

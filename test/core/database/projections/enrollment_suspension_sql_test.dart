import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/projections/enrollment_suspension_sql.dart';
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

  test('project : INACTIVE si ouverte, ACTIVE sinon, sans condition', () async {
    await insertMember(db, 's1');
    await insertMember(db, 's2', status: 'INACTIVE');
    await period('s1');

    await EnrollmentSuspensionSql.project(db, ['s1', 's2']);

    expect(await memberStatus(db, 's1'), 'INACTIVE');
    expect(await memberStatus(db, 's2'), 'ACTIVE');
  });

  test('project ne touche que l\'année de la période', () async {
    await insertMember(db, 's1');
    await insertMember(db, 's1', year: 'year-0');
    await period('s1');

    await EnrollmentSuspensionSql.project(db, ['s1']);

    expect(await memberStatus(db, 's1'), 'INACTIVE');
    expect(await memberStatus(db, 's1', year: 'year-0'), 'ACTIVE');
  });

  test('après un pull de membres : un élève sans période garde le statut '
      'du serveur', () async {
    await insertMember(db, 's1', status: 'INACTIVE');
    await insertMember(db, 's2');
    await period('s2');

    await EnrollmentSuspensionSql.reapplyAfterMemberPull(db, ['s1', 's2']);

    expect(await memberStatus(db, 's1'), 'INACTIVE');
    expect(await memberStatus(db, 's2'), 'INACTIVE');
  });

  test(
    'après un pull de membres : une période fermée rend l\'élève actif',
    () async {
      await insertMember(db, 's1', status: 'INACTIVE');
      await period('s1', reactivatedAt: '2026-10-09T08:00:00Z');

      await EnrollmentSuspensionSql.reapplyAfterMemberPull(db, ['s1']);

      expect(await memberStatus(db, 's1'), 'ACTIVE');
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

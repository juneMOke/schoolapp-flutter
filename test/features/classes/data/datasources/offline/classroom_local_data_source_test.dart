import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late ClassroomLocalDataSource dao;

  const yearId = 'year-1';
  const classroomId = 'class-a';

  ClassroomDto classroom({
    String id = classroomId,
    String name = 'A1',
    String? levelId = 'level-1',
    int total = 30,
    int female = 16,
    int male = 13,
    int? updatedAt = 1000,
  }) => ClassroomDto(
    id: id,
    academicYearId: yearId,
    schoolLevelId: levelId,
    name: name,
    totalCount: total,
    femaleCount: female,
    maleCount: male,
    updatedAt: updatedAt,
  );

  ClassroomMemberDto member({
    required String id,
    required String first,
    required String last,
    String gender = 'MALE',
    String status = 'ACTIVE',
    String classroom = classroomId,
  }) => ClassroomMemberDto(
    id: id,
    studentId: 'stu-$id',
    classroomId: classroom,
    academicYearId: yearId,
    studentFirstName: first,
    studentLastName: last,
    studentGender: gender,
    status: status,
  );

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ClassroomLocalDataSource(db);
  });

  tearDown(() async => db.close());

  test('upsertDelta insère classes et membres avec synced_at', () async {
    await dao.upsertDelta(
      classrooms: [classroom()],
      members: [member(id: 'm1', first: 'John', last: 'Doe')],
      syncedAt: 5000,
    );

    final classes = await dao.getClassrooms(academicYearId: yearId);
    expect(classes, hasLength(1));
    expect(classes.first.name, 'A1');

    final rows = await db.query('ref_classrooms');
    expect(rows.first['synced_at'], 5000);
  });

  test('upsertDelta est idempotent (REPLACE sur la PK)', () async {
    await dao.upsertDelta(
      classrooms: [classroom(total: 30)],
      members: const [],
      syncedAt: 1000,
    );
    await dao.upsertDelta(
      classrooms: [classroom(total: 31)],
      members: const [],
      syncedAt: 2000,
    );

    final classes = await dao.getClassrooms(academicYearId: yearId);
    expect(classes, hasLength(1));
    expect(classes.first.totalCount, 31);
  });

  test('les compteurs ne supposent pas total = female + male', () async {
    // 30 total, 16F + 13G = 29 → 1 élève OTHER inclus dans le total.
    await dao.upsertDelta(
      classrooms: [classroom(total: 30, female: 16, male: 13)],
      members: const [],
      syncedAt: 1000,
    );
    final c = (await dao.getClassrooms(academicYearId: yearId)).first;
    expect(c.totalCount, 30);
    expect(c.femaleCount + c.maleCount, 29);
  });

  test('getClassrooms filtre par niveau', () async {
    await dao.upsertDelta(
      classrooms: [
        classroom(id: 'c1', levelId: 'level-1'),
        classroom(id: 'c2', levelId: 'level-2'),
      ],
      members: const [],
      syncedAt: 1000,
    );
    final level1 = await dao.getClassrooms(
      academicYearId: yearId,
      schoolLevelId: 'level-1',
    );
    expect(level1.map((c) => c.id), ['c1']);
  });

  test('getRoster ne renvoie que les ACTIVE, trié', () async {
    await dao.upsertDelta(
      classrooms: [classroom()],
      members: [
        member(id: 'm1', first: 'Bob', last: 'Zulu'),
        member(id: 'm2', first: 'Alice', last: 'Alpha'),
        member(id: 'm3', first: 'Gone', last: 'Away', status: 'INACTIVE'),
      ],
      syncedAt: 1000,
    );
    final roster = await dao.getRoster(classroomId);
    expect(roster.map((m) => m.id), ['m2', 'm1']); // Alpha avant Zulu
  });

  test('searchRoster est insensible à la casse (nom/prénom)', () async {
    await dao.upsertDelta(
      classrooms: [classroom()],
      members: [
        member(id: 'm1', first: 'Jean', last: 'Dupont'),
        member(id: 'm2', first: 'Marie', last: 'Curie'),
      ],
      syncedAt: 1000,
    );
    final byLast = await dao.searchRoster(
      classroomId: classroomId,
      query: 'dup',
    );
    expect(byLast.map((m) => m.id), ['m1']);
    final byFirst = await dao.searchRoster(
      classroomId: classroomId,
      query: 'MARIE',
    );
    expect(byFirst.map((m) => m.id), ['m2']);
  });

  test('searchRoster vide = roster complet', () async {
    await dao.upsertDelta(
      classrooms: [classroom()],
      members: [member(id: 'm1', first: 'Jean', last: 'Dupont')],
      syncedAt: 1000,
    );
    final all = await dao.searchRoster(classroomId: classroomId, query: '  ');
    expect(all, hasLength(1));
  });

  test('countActiveRoster ignore les INACTIVE', () async {
    await dao.upsertDelta(
      classrooms: [classroom()],
      members: [
        member(id: 'm1', first: 'A', last: 'A'),
        member(id: 'm2', first: 'B', last: 'B'),
        member(id: 'm3', first: 'C', last: 'C', status: 'INACTIVE'),
      ],
      syncedAt: 1000,
    );
    expect(await dao.countActiveRoster(classroomId), 2);
  });

  test('round-trip fromMap/toMap conserve les champs', () async {
    final dto = classroom(updatedAt: 42);
    await dao.upsertDelta(classrooms: [dto], members: const [], syncedAt: 99);
    final loaded = await dao.getClassroomById(classroomId);
    expect(loaded, isNotNull);
    expect(loaded!.updatedAt, 42);
    expect(loaded.femaleCount, 16);
  });
}

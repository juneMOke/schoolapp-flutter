import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/course_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockOnlineCourse extends Mock implements CourseRepository {}

void main() {
  late Database db;
  late CourseOfflineRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    repo = CourseOfflineRepositoryImpl(
      online: MockOnlineCourse(),
      scheduleRefLocalDataSource: ScheduleRefLocalDataSource(db),
      classroomLocalDataSource: ClassroomLocalDataSource(db),
      currentUser: CurrentUserContext()..set('me'),
    );
  });

  tearDown(() async => db.close());

  Future<void> insertSession(
    String id,
    String coursId,
    String classroomId,
    String teacherId,
    String subject,
  ) => db.insert('ref_recurring_sessions', {
    'id': id,
    'academic_year_id': 'ay-1',
    'cours_id': coursId,
    'time_slot_id': 't1',
    'day_of_week': 'MON',
    'teacher_id': teacherId,
    'classroom_id': classroomId,
    'teacher_label': 'M. Moi',
    'classroom_label': '3e A',
    'subject_label': subject,
    'synced_at': 1,
  });

  test('getMyCourses : filtre par teacher_id=uid, groupe par classe', () async {
    await insertSession('s1', 'co1', 'class-1', 'me', 'Maths');
    // 2e créneau du MÊME cours → ne doit pas dupliquer le cours.
    await insertSession('s2', 'co1', 'class-1', 'me', 'Maths');
    await insertSession('s3', 'co2', 'class-1', 'me', 'Physique');
    // cours d'un AUTRE enseignant → exclu.
    await insertSession('s4', 'co9', 'class-2', 'autre', 'Chimie');
    // Classe résolue via ref_classrooms (compteurs).
    await db.insert('ref_classrooms', {
      'id': 'class-1',
      'academic_year_id': 'ay-1',
      'name': '3ème A',
      'total_count': 30,
      'female_count': 16,
      'male_count': 14,
    });

    final result = await repo.getMyCourses();

    final summaries = result.getOrElse(() => fail('Left'));
    expect(summaries.length, 1, reason: 'seule class-1 (mes cours)');
    final s = summaries.single;
    expect(s.classroom.id, 'class-1');
    expect(s.classroom.name, '3ème A', reason: 'résolu via ref_classrooms');
    expect(s.classroom.totalCount, 30);
    expect(s.courses.map((c) => c.id).toSet(), {
      'co1',
      'co2',
    }, reason: 'cours distincts, pas de doublon');
  });

  test(
    'getMyCourses : uid nul → liste vide (aucune donnée d\'un autre)',
    () async {
      await insertSession('s1', 'co1', 'class-1', 'me', 'Maths');
      final repoNoUser = CourseOfflineRepositoryImpl(
        online: MockOnlineCourse(),
        scheduleRefLocalDataSource: ScheduleRefLocalDataSource(db),
        classroomLocalDataSource: ClassroomLocalDataSource(db),
        currentUser: CurrentUserContext(),
      );

      final result = await repoNoUser.getMyCourses();

      expect(result.getOrElse(() => fail('Left')), isEmpty);
    },
  );
}

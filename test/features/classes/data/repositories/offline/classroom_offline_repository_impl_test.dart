import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_sync_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_delta_model.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_offline_repository_impl.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockClassroomSyncApi extends Mock implements ClassroomSyncApi {}

void main() {
  late Database db;
  late MockClassroomSyncApi api;
  late ClassroomLocalDataSource local;
  late SyncMetaDao syncMeta;
  late ClassroomOfflineRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const yearId = 'year-1';
  var clock = 10000;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockClassroomSyncApi();
    local = ClassroomLocalDataSource(db);
    syncMeta = SyncMetaDao(db);
    clock = 10000;
    repo = ClassroomOfflineRepositoryImpl(
      syncApi: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => clock,
    );
  });

  tearDown(() async => db.close());

  ClassroomDto classroom(String id, {int total = 30}) => ClassroomDto(
    id: id,
    academicYearId: yearId,
    schoolLevelId: 'level-1',
    name: id.toUpperCase(),
    totalCount: total,
    femaleCount: 15,
    maleCount: 14,
    updatedAt: 900,
  );

  ClassroomMemberDto member(String id, {String status = 'ACTIVE'}) =>
      ClassroomMemberDto(
        id: id,
        studentId: 'stu-$id',
        classroomId: 'c1',
        academicYearId: yearId,
        studentFirstName: 'First$id',
        studentLastName: 'Last$id',
        studentGender: 'FEMALE',
        status: status,
      );

  group('syncClassrooms', () {
    test('upsert local + avance le curseur + fraîcheur', () async {
      when(() => api.pullClassrooms(any(), yearId, any())).thenAnswer(
        (_) async => ClassroomDeltaModel(
          classrooms: [classroom('c1')],
          members: [member('m1')],
          serverCursor: 1234,
        ),
      );

      final result = await repo.syncClassrooms(academicYearId: yearId);

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.notModified, isFalse);
      expect(outcome.classroomsUpserted, 1);
      expect(outcome.membersUpserted, 1);
      expect(await syncMeta.getCursor('classrooms'), 1234);
      expect(await syncMeta.getSyncedAt('classrooms'), 10000);
      expect(await local.countActiveRoster('c1'), 1);
    });

    test('passe le curseur mémorisé comme updatedSince', () async {
      await syncMeta.setCursor('classrooms', cursor: 500, syncedAt: 1);
      when(
        () => api.pullClassrooms(any(), yearId, any()),
      ).thenAnswer((_) async => const ClassroomDeltaModel(serverCursor: 600));

      await repo.syncClassrooms(academicYearId: yearId);

      verify(() => api.pullClassrooms(auth, yearId, 500)).called(1);
    });

    test(
      'delta vide → notModified, curseur conservé, fraîcheur bumpée',
      () async {
        await syncMeta.setCursor('classrooms', cursor: 777, syncedAt: 1);
        when(
          () => api.pullClassrooms(any(), yearId, any()),
        ).thenAnswer((_) async => const ClassroomDeltaModel());

        final result = await repo.syncClassrooms(academicYearId: yearId);

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        expect(await syncMeta.getCursor('classrooms'), 777);
        expect(await syncMeta.getSyncedAt('classrooms'), 10000);
      },
    );

    test('DioException 304 → notModified sans écriture', () async {
      await syncMeta.setCursor('classrooms', cursor: 777, syncedAt: 1);
      when(() => api.pullClassrooms(any(), yearId, any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/sync/classrooms'),
          response: Response(
            requestOptions: RequestOptions(path: '/sync/classrooms'),
            statusCode: 304,
          ),
        ),
      );

      final result = await repo.syncClassrooms(academicYearId: yearId);

      expect(result.isRight(), isTrue);
      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.notModified, isTrue);
      expect(await syncMeta.getCursor('classrooms'), 777);
    });

    test('DioException porteuse d\'un Failure → Left', () async {
      when(() => api.pullClassrooms(any(), yearId, any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/sync/classrooms'),
          error: const UnauthorizedFailure(),
        ),
      );

      final result = await repo.syncClassrooms(academicYearId: yearId);
      expect(result, isA<Left<Failure, dynamic>>());
    });
  });

  group('lectures offline', () {
    setUp(() async {
      await local.upsertDelta(
        classrooms: [classroom('c1')],
        members: [
          member('m1'),
          member('m2', status: 'INACTIVE'),
        ],
        syncedAt: 8888,
      );
      await syncMeta.setCursor('classrooms', cursor: 1, syncedAt: 8888);
    });

    test('getClassrooms expose la fraîcheur (synced_at)', () async {
      final result = await repo.getClassrooms(academicYearId: yearId);
      final list = result.getOrElse(() => []);
      expect(list, hasLength(1));
      expect(list.first.syncedAt, 8888);
    });

    test('getRoster ne renvoie que les ACTIVE', () async {
      final result = await repo.getRoster(classroomId: 'c1');
      expect(result.getOrElse(() => []).map((m) => m.id), ['m1']);
    });

    test('getFreshness renvoie synced_at', () async {
      expect(await repo.getFreshness(), 8888);
    });

    test('getClassroom absent → NotFoundFailure', () async {
      final result = await repo.getClassroom(classroomId: 'ghost');
      expect(result, isA<Left<Failure, dynamic>>());
    });
  });
}

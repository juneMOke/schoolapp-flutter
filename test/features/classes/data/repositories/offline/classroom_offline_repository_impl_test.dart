import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_sync_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_delta_model.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_offline_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockClassroomSyncApi extends Mock implements ClassroomSyncApi {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late Database db;
  late MockClassroomSyncApi api;
  late ClassroomLocalDataSource local;
  late SyncMetaDao syncMeta;
  late MockSyncEngine syncEngine;
  late ClassroomOfflineRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const yearId = 'year-1';
  var clock = 10000;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockClassroomSyncApi();
    local = ClassroomLocalDataSource(db);
    syncMeta = SyncMetaDao(db);
    syncEngine = MockSyncEngine();
    when(
      () => syncEngine.flush(),
    ).thenAnswer((_) async => const SyncFlushReport());
    clock = 10000;
    repo = ClassroomOfflineRepositoryImpl(
      syncApi: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      idGenerator: const IdGenerator(Uuid()),
      syncEngine: syncEngine,
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
          serverCursor: '2026-06-01T08:00:00.000Z',
        ),
      );

      final result = await repo.syncClassrooms(academicYearId: yearId);

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.notModified, isFalse);
      expect(outcome.classroomsUpserted, 1);
      expect(outcome.membersUpserted, 1);
      expect(
        await syncMeta.getCursor('classrooms'),
        '2026-06-01T08:00:00.000Z',
      );
      expect(await syncMeta.getSyncedAt('classrooms'), 10000);
      expect(await local.countActiveRoster('c1'), 1);
    });

    test('passe le curseur mémorisé comme updatedSince', () async {
      await syncMeta.setCursor(
        'classrooms',
        cursor: '2026-06-02T08:00:00.000Z',
        syncedAt: 1,
      );
      when(() => api.pullClassrooms(any(), yearId, any())).thenAnswer(
        (_) async =>
            const ClassroomDeltaModel(serverCursor: '2026-06-03T08:00:00.000Z'),
      );

      await repo.syncClassrooms(academicYearId: yearId);

      verify(
        () => api.pullClassrooms(auth, yearId, '2026-06-02T08:00:00.000Z'),
      ).called(1);
    });

    test(
      'delta vide → notModified, curseur conservé, fraîcheur bumpée',
      () async {
        await syncMeta.setCursor(
          'classrooms',
          cursor: '2026-06-04T08:00:00.000Z',
          syncedAt: 1,
        );
        when(
          () => api.pullClassrooms(any(), yearId, any()),
        ).thenAnswer((_) async => const ClassroomDeltaModel());

        final result = await repo.syncClassrooms(academicYearId: yearId);

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        expect(
          await syncMeta.getCursor('classrooms'),
          '2026-06-04T08:00:00.000Z',
        );
        expect(await syncMeta.getSyncedAt('classrooms'), 10000);
      },
    );

    test('DioException 304 → notModified sans écriture', () async {
      await syncMeta.setCursor(
        'classrooms',
        cursor: '2026-06-04T08:00:00.000Z',
        syncedAt: 1,
      );
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
      expect(
        await syncMeta.getCursor('classrooms'),
        '2026-06-04T08:00:00.000Z',
      );
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
      await syncMeta.setCursor(
        'classrooms',
        cursor: '2026-06-05T08:00:00.000Z',
        syncedAt: 8888,
      );
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

  group('recordTransfer (offline, composition à la lecture)', () {
    setUp(() async {
      await local.upsertDelta(
        classrooms: [classroom('c1'), classroom('c2')],
        members: [member('m1')], // m1 dans c1 (miroir)
        syncedAt: 8888,
      );
    });

    RecordClassroomTransferDraft draft() => const RecordClassroomTransferDraft(
      studentId: 'stu-m1',
      fromClassroomId: 'c1',
      toClassroomId: 'c2',
      schoolLevelId: 'level-1',
      academicYearId: yearId,
    );

    test(
      'écrit l\'événement + enfile l\'outbox + flush opportuniste',
      () async {
        final result = await repo.recordTransfer(draft());

        expect(result.isRight(), isTrue);
        final transferId = result.getOrElse(() => '');
        expect(transferId, isNotEmpty);

        final transfers = await db.query('classroom_transfers');
        expect(transfers, hasLength(1));
        expect(transfers.first['sync_status'], 'PENDING_SYNC');
        expect(transfers.first['to_classroom_id'], 'c2');

        final outbox = await db.query('outbox');
        expect(outbox, hasLength(1));
        expect(outbox.first['aggregate_type'], 'CLASSROOM_TRANSFER');
        expect(outbox.first['aggregate_id'], transferId);

        verify(() => syncEngine.flush()).called(1);
      },
    );

    test('le miroir ref_classroom_members n\'est PAS muté', () async {
      await repo.recordTransfer(draft());
      final rows = await db.query(
        'ref_classroom_members',
        where: 'id = ?',
        whereArgs: ['m1'],
      );
      // Le miroir reste sur c1 : la classe courante se compose à la lecture.
      expect(rows.single['classroom_id'], 'c1');
    });

    test(
      'roster composé : m1 quitte c1 et apparaît dans c2 (pending)',
      () async {
        await repo.recordTransfer(draft());

        final c1 = await repo.getRoster(classroomId: 'c1');
        expect(c1.getOrElse(() => []), isEmpty);

        final c2 = await repo.getRoster(classroomId: 'c2');
        final list = c2.getOrElse(() => []);
        expect(list.map((m) => m.id), ['m1']);
        expect(list.single.hasPendingTransfer, isTrue);
      },
    );

    test(
      'getComposedRosters : map par classe reflète le transfert pending',
      () async {
        await repo.recordTransfer(draft());

        final result = await repo.getComposedRosters(
          academicYearId: yearId,
          schoolLevelId: 'level-1',
        );
        final map = result.getOrElse(() => {});
        expect(map.keys, containsAll(['c1', 'c2']));
        expect(map['c1'], isEmpty);
        expect(map['c2']!.single.id, 'm1');
        expect(map['c2']!.single.hasPendingTransfer, isTrue);
      },
    );
  });
}

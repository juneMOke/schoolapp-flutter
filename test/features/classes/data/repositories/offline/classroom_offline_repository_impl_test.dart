import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_offline_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_member_pull_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_pull_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_member_pull_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_pull_repository.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockClassroomPullRepository extends Mock
    implements ClassroomPullRepository {}

class MockClassroomMemberPullRepository extends Mock
    implements ClassroomMemberPullRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late Database db;
  late MockClassroomPullRepository classroomPull;
  late MockClassroomMemberPullRepository memberPull;
  late ClassroomLocalDataSource local;
  late SyncMetaDao syncMeta;
  late MockSyncEngine syncEngine;
  late ClassroomOfflineRepositoryImpl repo;

  const yearId = 'year-1';
  var clock = 10000;

  setUp(() async {
    db = await openFullOfflineDb();
    classroomPull = MockClassroomPullRepository();
    memberPull = MockClassroomMemberPullRepository();
    local = ClassroomLocalDataSource(db);
    syncMeta = SyncMetaDao(db);
    syncEngine = MockSyncEngine();
    when(
      () => syncEngine.flush(),
    ).thenAnswer((_) async => const SyncFlushReport());
    clock = 10000;
    repo = ClassroomOfflineRepositoryImpl(
      classroomPullRepository: classroomPull,
      classroomMemberPullRepository: memberPull,
      localDataSource: local,
      syncMetaDao: syncMeta,
      idGenerator: const IdGenerator(Uuid()),
      syncEngine: syncEngine,
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

  group('syncClassrooms (orchestration des deux flux dédiés)', () {
    test('agrège les deux Right (upserted + notModified combinés)', () async {
      when(
        () => classroomPull.syncClassrooms(
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          ClassroomPullOutcome(upserted: 2, notModified: false, syncedAt: 1),
        ),
      );
      when(
        () => memberPull.syncMembers(
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer(
        (_) async =>
            const Right(ClassroomMemberPullOutcome.notModifiedAt(1, 'cur')),
      );

      final result = await repo.syncClassrooms(academicYearId: yearId);

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.classroomsUpserted, 2);
      expect(outcome.membersUpserted, 0);
      // notModified agrégé = ET logique des deux flux.
      expect(outcome.notModified, isFalse);
      expect(outcome.syncedAt, 10000);
      verify(
        () => classroomPull.syncClassrooms(academicYearId: yearId),
      ).called(1);
      verify(() => memberPull.syncMembers(academicYearId: yearId)).called(1);
    });

    test('les deux flux notModified → outcome notModified', () async {
      when(
        () => classroomPull.syncClassrooms(
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer(
        (_) async => const Right(ClassroomPullOutcome.notModifiedAt(1, 'c')),
      );
      when(
        () => memberPull.syncMembers(
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer(
        (_) async =>
            const Right(ClassroomMemberPullOutcome.notModifiedAt(1, 'm')),
      );

      final result = await repo.syncClassrooms(academicYearId: yearId);

      expect(
        result.getOrElse(() => throw StateError('left')).notModified,
        isTrue,
      );
    });

    test(
      'échec du flux classrooms → Left, flux membres quand même appelé',
      () async {
        when(
          () => classroomPull.syncClassrooms(
            academicYearId: any(named: 'academicYearId'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure('down')));
        when(
          () => memberPull.syncMembers(
            academicYearId: any(named: 'academicYearId'),
          ),
        ).thenAnswer(
          (_) async =>
              const Right(ClassroomMemberPullOutcome.notModifiedAt(1, 'm')),
        );

        final result = await repo.syncClassrooms(academicYearId: yearId);

        expect(result, isA<Left<Failure, dynamic>>());
        verify(() => memberPull.syncMembers(academicYearId: yearId)).called(1);
      },
    );

    test('échec du flux membres → Left', () async {
      when(
        () => classroomPull.syncClassrooms(
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer(
        (_) async => const Right(ClassroomPullOutcome.notModifiedAt(1, 'c')),
      );
      when(
        () => memberPull.syncMembers(
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('boom')));

      final result = await repo.syncClassrooms(academicYearId: yearId);

      expect(result, isA<Left<Failure, dynamic>>());
    });
  });

  group('lectures offline', () {
    setUp(() async {
      await local.upsertClassrooms(
        classrooms: [classroom('c1')],
        syncedAt: 8888,
      );
      await local.upsertMembers(
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
      await local.upsertClassrooms(
        classrooms: [classroom('c1'), classroom('c2')],
        syncedAt: 8888,
      );
      await local.upsertMembers(
        members: [member('m1')],
        syncedAt: 8888,
      ); // m1 dans c1 (miroir)
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

  group('upsertAssignedMember (intégration du 201 d\'affectation)', () {
    setUp(() async {
      await local.upsertClassrooms(
        classrooms: [classroom('c1'), classroom('c2')],
        syncedAt: 8888,
      );
    });

    const created = ClassroomMember(
      id: 'm-new',
      studentId: 's-new',
      classroomId: 'c2',
      academicYearId: yearId,
      studentFirstName: 'Jane',
      studentLastName: 'Doe',
      studentMiddleName: 'K',
      studentGender: ClassroomMemberGender.female,
    );

    test(
      'le membre créé apparaît aussitôt dans le roster de la classe',
      () async {
        final result = await repo.upsertAssignedMember(created);

        expect(result.isRight(), isTrue);
        final roster = await repo.getRoster(classroomId: 'c2');
        expect(roster.getOrElse(() => []).map((m) => m.id), ['m-new']);
      },
    );

    test(
      'genre réécrit au format wire (lecture aller-retour fidèle)',
      () async {
        await repo.upsertAssignedMember(created);

        final roster = await repo.getRoster(classroomId: 'c2');
        expect(
          roster.getOrElse(() => []).single.studentGender,
          ClassroomMemberGender.female,
        );
      },
    );

    test('ligne ACTIVE : elle compte dans les rosters composés', () async {
      await repo.upsertAssignedMember(created);

      final composed = await repo.getComposedRosters(
        academicYearId: yearId,
        schoolLevelId: 'level-1',
      );
      final map = composed.getOrElse(() => {});
      expect(map['c2']!.single.id, 'm-new');
      expect(map['c1'], isEmpty);
    });

    test('rejeu idempotent : pas de doublon de roster', () async {
      await repo.upsertAssignedMember(created);
      await repo.upsertAssignedMember(created);

      final roster = await repo.getRoster(classroomId: 'c2');
      expect(roster.getOrElse(() => []), hasLength(1));
    });

    test('base fermée → StorageFailure, jamais une exception', () async {
      await db.close();

      final result = await repo.upsertAssignedMember(created);

      expect(result, isA<Left<Failure, void>>());
      // Réouverture pour que le tearDown n'échoue pas sur un double close.
      db = await openFullOfflineDb();
    });
  });
}

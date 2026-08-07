import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_outbox_handler.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_sync_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_ack.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockClassroomTransferSyncApi extends Mock
    implements ClassroomTransferSyncApi {}

void main() {
  late Database db;
  late ClassroomLocalDataSource local;
  late MockClassroomTransferSyncApi api;
  late ClassroomTransferOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    local = ClassroomLocalDataSource(db);
    api = MockClassroomTransferSyncApi();
    handler = ClassroomTransferOutboxHandler(
      api: api,
      localDataSource: local,
      extras: auth,
      now: () => 5000,
    );

    // État de départ : c1 (30) + c2 (20), m1 dans c1, transfert t1 PENDING.
    await db.insert('ref_classrooms', {
      'id': 'c1',
      'academic_year_id': 'y1',
      'school_level_id': 'lvl',
      'name': 'A',
      'total_count': 30,
      'female_count': 15,
      'male_count': 15,
    });
    await db.insert('ref_classrooms', {
      'id': 'c2',
      'academic_year_id': 'y1',
      'school_level_id': 'lvl',
      'name': 'B',
      'total_count': 20,
      'female_count': 10,
      'male_count': 10,
    });
    await db.insert('ref_classroom_members', {
      'id': 'm1',
      'student_id': 's1',
      'classroom_id': 'c1',
      'academic_year_id': 'y1',
      'student_first_name': 'Jane',
      'student_last_name': 'Doe',
      'student_gender': 'FEMALE',
      'status': 'ACTIVE',
    });
    await db.insert('classroom_transfers', {
      'id': 't1',
      'student_id': 's1',
      'from_classroom_id': 'c1',
      'to_classroom_id': 'c2',
      'school_level_id': 'lvl',
      'academic_year_id': 'y1',
      'transferred_at': 4000,
      'sync_status': 'PENDING_SYNC',
    });
  });

  tearDown(() async => db.close());

  OutboxEntry entry() => OutboxEntry(
    id: 'ob-1',
    aggregateType: 'CLASSROOM_TRANSFER',
    aggregateId: 't1',
    operation: OutboxOperation.create,
    payload: jsonEncode({
      'transfer': {
        'id': 't1',
        'studentId': 's1',
        'fromClassroomId': 'c1',
        'toClassroomId': 'c2',
        'academicYearId': 'y1',
        'transferredAt': '2026-07-18T10:00:00.000Z',
      },
    }),
    createdAt: 4000,
  );

  ClassroomTransferAck ack() => const ClassroomTransferAck(
    transferId: 't1',
    membership: ClassroomMembershipAck(
      studentId: 's1',
      classroomId: 'c2',
      academicYearId: 'y1',
      status: 'ACTIVE',
    ),
    classrooms: [
      ClassroomCountsAck(
        id: 'c1',
        totalCount: 29,
        femaleCount: 14,
        maleCount: 15,
      ),
      ClassroomCountsAck(
        id: 'c2',
        totalCount: 21,
        femaleCount: 11,
        maleCount: 10,
      ),
    ],
  );

  test(
    'succès → ACK atomique : miroir déplacé, compteurs des 2 classes, SYNCED',
    () async {
      when(
        () => api.submitTransfer(auth, any()),
      ).thenAnswer((_) async => ack());

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      // Miroir repositionné sur c2.
      final member = (await db.query(
        'ref_classroom_members',
        where: 'id = ?',
        whereArgs: ['m1'],
      )).single;
      expect(member['classroom_id'], 'c2');
      // Compteurs recalculés des DEUX classes.
      final c1 = (await db.query(
        'ref_classrooms',
        where: 'id = ?',
        whereArgs: ['c1'],
      )).single;
      final c2 = (await db.query(
        'ref_classrooms',
        where: 'id = ?',
        whereArgs: ['c2'],
      )).single;
      expect(c1['total_count'], 29);
      expect(c2['total_count'], 21);
      // Transfert scellé SYNCED (sort du pending → la composition ne l'applique plus).
      final t = (await db.query(
        'classroom_transfers',
        where: 'id = ?',
        whereArgs: ['t1'],
      )).single;
      expect(t['sync_status'], 'SYNCED');
      expect(t['synced_at'], 5000);
    },
  );

  test('422 LEVEL_MISMATCH → failed (poison, SYNC_ERROR)', () async {
    when(() => api.submitTransfer(auth, any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 422,
        ),
      ),
    );

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
    // Rien n'a bougé : le miroir reste sur c1.
    final member = (await db.query(
      'ref_classroom_members',
      where: 'id = ?',
      whereArgs: ['m1'],
    )).single;
    expect(member['classroom_id'], 'c1');
  });

  test('réseau / 5xx → retry (transitoire)', () async {
    when(() => api.submitTransfer(auth, any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 503,
        ),
      ),
    );

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('payload illisible → failed (poison)', () async {
    const bad = OutboxEntry(
      id: 'ob-2',
      aggregateType: 'CLASSROOM_TRANSFER',
      aggregateId: 't1',
      operation: OutboxOperation.create,
      payload: 'not-json',
      createdAt: 4000,
    );
    final result = await handler.dispatch(bad);
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });
}

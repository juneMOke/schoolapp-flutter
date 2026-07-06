import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

import '../../offline_full_db.dart';

class MockEnrollmentSyncApi extends Mock implements EnrollmentSyncApi {}

void main() {
  late Database db;
  late EnrollmentLocalDao dao;
  late MockEnrollmentSyncApi api;
  late EnrollmentOutboxHandler handler;

  setUpAll(() {
    registerFallbackValue(const EnrollmentCommitBatch([]));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EnrollmentLocalDao(db);
    api = MockEnrollmentSyncApi();
    handler = EnrollmentOutboxHandler(
      api: api,
      dao: dao,
      extras: const {},
      now: () => 9000,
    );

    await dao.confirmEnrollment(
      student: const StudentLocalModel(
        id: 's1',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        updatedAt: 100,
      ),
      enrollment: const EnrollmentLocalModel(
        id: 'e1',
        studentId: 's1',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-1',
        enrollmentDate: '2026-07-06',
      ),
      parents: [
        const ParentDraft(
          parent: ParentLocalModel(
            id: 'p-prov',
            firstName: 'Sarah',
            lastName: 'Moke',
            phoneNumber: '+243111',
          ),
          relationshipType: 'MOTHER',
        ),
      ],
      document: const GeneratedDocumentLocalModel(
        id: 'd1',
        docDomain: 'ENROLLMENT',
        enrollmentId: 'e1',
        studentId: 's1',
        docType: 'AI',
        number: 'PROV-ABCDEF12',
      ),
      outboxEntryId: 'ob1',
      nowMs: 1000,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<OutboxEntry> pendingEntry() async =>
      (await OutboxDao(db).pendingReady(9999)).single;

  test('COMMITTED → acked + remap appliqué en base', () async {
    when(() => api.commit(any(), any())).thenAnswer(
      (_) async => const EnrollmentCommitResult([
        EnrollmentAck(
          clientEnrollmentId: 'e1',
          outcome: 'COMMITTED',
          enrollment: AckEnrollment(id: 'e1', enrollmentCode: 'ETL-1'),
          student: AckStudent(id: 's1', matriculationNumber: 'MAT-1'),
          parents: [AckParent(clientId: 'p-prov', id: 'p-canon')],
          document: AckDocument(id: 'd1', number: 'ETL-AI-1'),
        ),
      ]),
    );

    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.acked);

    final s = (await db.query('students')).first;
    expect(s['matriculation_number'], 'MAT-1');
    expect(s['sync_status'], SyncState.synced.dbValue);
    expect((await db.query('parents')).first['id'], 'p-canon');
    expect(
      (await db.query('generated_documents')).first['status'],
      'DEFINITIVE',
    );
  });

  test('VALIDATION_ERROR → failed + SYNC_ERROR local', () async {
    when(() => api.commit(any(), any())).thenAnswer(
      (_) async => const EnrollmentCommitResult([
        EnrollmentAck(
          clientEnrollmentId: 'e1',
          outcome: 'VALIDATION_ERROR',
          error: AckError(message: 'Champ requis'),
        ),
      ]),
    );

    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
    expect(result.error, 'Champ requis');
    expect(
      (await db.query('enrollments')).first['sync_status'],
      SyncState.syncError.dbValue,
    );
  });

  test('erreur réseau (DioException) → retry (idempotent)', () async {
    when(() => api.commit(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: 'net',
      ),
    );

    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
    // Rien n'a changé : le dossier reste PENDING_SYNC.
    expect(
      (await db.query('enrollments')).first['sync_status'],
      SyncState.pendingSync.dbValue,
    );
  });

  test('ACK absent pour l\'agrégat → retry', () async {
    when(
      () => api.commit(any(), any()),
    ).thenAnswer((_) async => const EnrollmentCommitResult([]));
    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

import '../../offline_full_db.dart';

class MockEnrollmentSyncApi extends Mock implements EnrollmentSyncApi {}

const _fallbackCommand = EnrollmentCommand(
  enrollment: EnrollmentPayload(
    id: 'e0',
    enrollmentType: 'NEW_ENROLLMENT',
    status: 'IN_PROGRESS',
    academicYearId: 'ay-0',
    enrollmentDate: '2026-01-01',
  ),
  student: StudentPayload(
    id: 's0',
    firstName: 'A',
    lastName: 'B',
    surname: 'C',
    gender: 'FEMALE',
    dateOfBirth: '2015-01-01',
    birthPlace: 'X',
    nationality: 'CD',
  ),
  parents: [],
);

DioException _httpError(int status, {Object? data}) => DioException(
  requestOptions: RequestOptions(path: '/api/v1/enrollments'),
  response: Response(
    requestOptions: RequestOptions(path: '/api/v1/enrollments'),
    statusCode: status,
    data: data,
  ),
);

void main() {
  late Database db;
  late EnrollmentDraftDao draftDao;
  late EnrollmentAckDao ackDao;
  late MockEnrollmentSyncApi api;
  late EnrollmentOutboxHandler handler;

  setUpAll(() {
    registerFallbackValue(const EnrollmentAggregateRequest(_fallbackCommand));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = await openFullOfflineDb();
    draftDao = EnrollmentDraftDao(db);
    ackDao = EnrollmentAckDao(db);
    api = MockEnrollmentSyncApi();
    handler = EnrollmentOutboxHandler(
      api: api,
      dao: ackDao,
      extras: const {},
      now: () => 9000,
    );

    // Dossier PENDING_SYNC + entrée outbox via le VRAI chemin de production
    // (draft-par-étape → finalize), l'ancien one-shot commit ayant été retiré.
    await draftDao.insertDraftStudent(
      const StudentLocalModel(
        id: 's1',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        updatedAt: 100,
      ),
    );
    await draftDao.insertDraftEnrollment(
      const EnrollmentLocalModel(
        id: 'e1',
        studentId: 's1',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-1',
        enrollmentDate: '2026-07-06',
      ),
    );
    await draftDao.replaceDraftParents('s1', [
      const ParentDraft(
        parent: ParentLocalModel(
          id: 'p-prov',
          firstName: 'Sarah',
          lastName: 'Moke',
          phoneNumber: '+243111',
        ),
        relationshipType: 'MOTHER',
      ),
    ], nowMs: 1000);
    await draftDao.finalizeDraft(
      'e1',
      document: const GeneratedDocumentLocalModel(
        id: 'd1',
        docDomain: 'ENROLLMENT',
        enrollmentId: 'e1',
        studentId: 's1',
        docType: 'AI',
        number: 'PROV-ABCDEF12',
      ),
      nowMs: 1000,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<OutboxEntry> pendingEntry() async =>
      (await OutboxDao(db).pendingReady(9999)).single;

  test('201/200 → acked + remap canonique appliqué en base', () async {
    when(() => api.submit(any(), any())).thenAnswer(
      (_) async => const EnrollmentAggregateResponse(
        enrollment: ResponseEnrollment(id: 'e1', enrollmentCode: 'ETL-1'),
        student: ResponseStudent(id: 's1', matriculationNumber: 'MAT-1'),
        parents: [ParentRemap(providedId: 'p-prov', canonicalId: 'p-canon')],
        documents: [
          GeneratedDocumentDto(
            type: 'ENROLLMENT_CERTIFICATE',
            documentNumber: 'ETL-AI-1',
            status: 'DEFINITIVE',
          ),
        ],
      ),
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

  test('422 → failed + SYNC_ERROR local (message extrait du corps)', () async {
    when(() => api.submit(any(), any())).thenThrow(
      _httpError(
        422,
        data: {'code': 'VALIDATION_FAILED', 'message': 'Champ requis'},
      ),
    );

    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
    expect(result.error, 'Champ requis');
    expect(
      (await db.query('enrollments')).first['sync_status'],
      SyncState.syncError.dbValue,
    );
    expect(
      (await db.query('students')).first['sync_status'],
      SyncState.syncError.dbValue,
    );
  });

  test(
    'erreur réseau (DioException sans réponse) → retry (idempotent)',
    () async {
      when(() => api.submit(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/enrollments'),
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
    },
  );

  test('5xx → retry (transitoire, pas un rejet métier)', () async {
    when(() => api.submit(any(), any())).thenThrow(_httpError(503));
    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
    expect(
      (await db.query('enrollments')).first['sync_status'],
      SyncState.pendingSync.dbValue,
    );
  });

  // 4xx client-terminal (hors 401/408/429) : rejeu inutile → SYNC_ERROR immédiat
  // au lieu de gaspiller maxAttempts avant un dead-letter générique.
  for (final status in [400, 403, 404, 409]) {
    test('$status (client-terminal) → failed + SYNC_ERROR immédiat', () async {
      when(
        () => api.submit(any(), any()),
      ).thenThrow(_httpError(status, data: {'message': 'Refusé ($status)'}));

      final result = await handler.dispatch(await pendingEntry());
      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(result.error, 'Refusé ($status)');
      expect(
        (await db.query('enrollments')).first['sync_status'],
        SyncState.syncError.dbValue,
      );
    });
  }

  test('4xx sans corps → SYNC_ERROR avec motif de repli', () async {
    when(() => api.submit(any(), any())).thenThrow(_httpError(400));
    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
    expect(result.error, 'Rejet serveur (400)');
  });

  // 401/408/429 restent transitoires (ré-auth / timeout / rate-limit).
  for (final status in [401, 408, 429]) {
    test(
      '$status → retry (transitoire, dossier conservé PENDING_SYNC)',
      () async {
        when(() => api.submit(any(), any())).thenThrow(_httpError(status));
        final result = await handler.dispatch(await pendingEntry());
        expect(result.outcome, OutboxDispatchOutcome.retry);
        expect(
          (await db.query('enrollments')).first['sync_status'],
          SyncState.pendingSync.dbValue,
        );
      },
    );
  }
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockMetierPullApi extends Mock implements AcademicsMetierPullApi {}

void main() {
  late Database db;
  late AcademicsLocalDataSource local;
  late AcademicsRefLocalDataSource refLocal;
  late SyncMetaDao syncMeta;
  late MockMetierPullApi api;
  late AcademicsMetierPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    refLocal = AcademicsRefLocalDataSource(db);
    syncMeta = SyncMetaDao(db);
    api = MockMetierPullApi();
    repo = AcademicsMetierPullRepositoryImpl(
      api: api,
      localDataSource: local,
      refLocalDataSource: refLocal,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  HttpResponse<T> httpOk<T>(T body) => HttpResponse(
    body,
    Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
  );

  DioException status(int code) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
    ),
  );

  Future<void> insertCours(String id) => db.insert('ref_cours', {
    'id': id,
    'classroom_id': 'class-1',
    'ligne_bareme_id': 'lb-1',
    'synced_at': 1,
  });

  group('applyPulledEvaluations : skip PENDING (jamais de clobber)', () {
    test(
      'saute une éval locale PENDING, insère l\'absente, rafraîchit SYNCED',
      () async {
        // Locale PENDING (créée offline, pas encore poussée).
        await db.insert('evaluation', {
          'id': 'ev-local',
          'cours_id': 'c1',
          'type': 'INTERRO',
          'eval_date': 1,
          'max_points': 20.0,
          'poids': 1,
          'updated_at': 1000,
          'sync_status': 'PENDING_SYNC',
        });

        final n = await local.applyPulledEvaluations([
          // même id qu'une locale PENDING → doit être SAUTÉE.
          const EvaluationRow(
            id: 'ev-local',
            coursId: 'c1',
            type: 'DEVOIR',
            evalDate: 2,
            maxPoints: 10,
            poids: 2,
            updatedAt: 5000,
            syncStatus: 'SYNCED',
          ),
          // absente → insérée SYNCED.
          const EvaluationRow(
            id: 'ev-server',
            coursId: 'c1',
            type: 'EXAMEN',
            evalDate: 3,
            maxPoints: 40,
            poids: 3,
            updatedAt: 5000,
            serverUpdatedAt: 5000,
            syncStatus: 'SYNCED',
          ),
        ]);

        expect(n, 1, reason: 'seule ev-server appliquée');
        final local1 = await local.getEvaluation('ev-local');
        expect(local1!.syncState, SyncState.pendingSync);
        expect(local1.type, 'INTERRO', reason: 'valeur locale préservée');
        expect(
          (await local.getEvaluation('ev-server'))!.syncState,
          SyncState.synced,
        );
      },
    );
  });

  group('applyPulledNotes : réconciliation SYNC_ERROR', () {
    test('une note locale SYNC_ERROR (rejet terminal) est RÉCONCILIÉE par la '
        'vérité serveur', () async {
      // Note rejetée terminalement (ex. période close) : le serveur a refusé,
      // sa version arbitrée doit remplacer la ligne locale — sinon la note
      // rejetée survivrait à jamais comme si elle était valide.
      await db.insert('note_evaluation', {
        'id': 'n-local',
        'evaluation_id': 'ev-1',
        'student_id': 's1',
        'points_obtenus': 18.0,
        'statut': 'NOTEE',
        'updated_at': 2000,
        'sync_status': 'SYNC_ERROR',
      });

      final n = await local.applyPulledNotes([
        const NoteEvaluationRow(
          id: 'n-server',
          evaluationId: 'ev-1',
          studentId: 's1',
          pointsObtenus: 12,
          statut: 'NOTEE',
          updatedAt: 9000,
          syncStatus: 'SYNCED',
        ),
      ]);

      expect(n, 1);
      final row = (await local.getNotesForEvaluation('ev-1')).single;
      expect(row.syncState, SyncState.synced, reason: 'réconciliée');
      expect(row.pointsObtenus, 12, reason: 'vérité serveur');
      expect(row.id, 'n-local', reason: 'PK de transport conservée');
    });
  });

  group('applyPulledNotes : skip PENDING (jamais de clobber)', () {
    test('saute une note locale PENDING sur la clé naturelle', () async {
      await local.upsertNotesWithOutbox(
        evaluationId: 'ev-1',
        incoming: [
          const NoteEvaluationRow(
            id: 'n-local',
            evaluationId: 'ev-1',
            studentId: 's1',
            pointsObtenus: 18,
            statut: 'NOTEE',
            updatedAt: 2000,
          ),
        ],
        buildOutboxEntry: (_) => const OutboxEntry(
          id: 'obx',
          aggregateType: 'ACADEMICS_NOTES_BATCH',
          aggregateId: 'ev-1',
          operation: OutboxOperation.upsert,
          payload: '{}',
          createdAt: 1,
        ),
      );

      final n = await local.applyPulledNotes([
        // même (ev-1, s1) que la locale PENDING → SAUTÉE.
        const NoteEvaluationRow(
          id: 'n-server',
          evaluationId: 'ev-1',
          studentId: 's1',
          pointsObtenus: 5,
          statut: 'NOTEE',
          updatedAt: 9000,
          syncStatus: 'SYNCED',
        ),
        // (ev-1, s2) absente → insérée SYNCED.
        const NoteEvaluationRow(
          id: 'n-s2',
          evaluationId: 'ev-1',
          studentId: 's2',
          pointsObtenus: 12,
          statut: 'NOTEE',
          updatedAt: 9000,
          syncStatus: 'SYNCED',
        ),
      ]);

      expect(n, 1);
      final byStudent = {
        for (final r in await local.getNotesForEvaluation('ev-1'))
          r.studentId: r,
      };
      expect(byStudent['s1']!.syncState, SyncState.pendingSync);
      expect(byStudent['s1']!.pointsObtenus, 18, reason: 'locale préservée');
      expect(byStudent['s2']!.syncState, SyncState.synced);
    });
  });

  group('pull itéré par cours, curseurs indépendants', () {
    EvaluationPageDto evalPage(String watermark) => EvaluationPageDto(
      items: [
        const EvaluationDeltaDto(
          id: 'ev-1',
          coursId: 'co1',
          type: 'INTERRO',
          date: '2026-06-10',
          maxPoints: 20,
          poids: 1,
          serverUpdatedAt: '2026-06-10T08:00:00Z',
        ),
      ],
      page: KeysetPageEnvelope(
        nextWatermark: watermark,
        hasMore: false,
        serverTime: '2026-06-10T10:00:00Z',
      ),
    );

    AcademicsDeltaPullOutcome right(
      Either<Failure, AcademicsDeltaPullOutcome> e,
    ) => e.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

    test('aucun cours local → no-op notModified', () async {
      final outcome = right(await repo.syncEvaluations());
      expect(outcome.notModified, isTrue);
      expect(outcome.serverTimeMs, isNull);
      verifyNever(() => api.pullEvaluations(any(), any(), any(), any()));
    });

    test('évaluations : curseur PAR cours ; notes indépendantes', () async {
      await insertCours('co1');
      when(
        () => api.pullEvaluations(auth, 'co1', null, 100),
      ).thenAnswer((_) async => httpOk(evalPage('wm-ev')));

      final outcome = right(await repo.syncEvaluations());

      expect(outcome.upserted, 1);
      // Horloge SERVEUR (page.serverTime), pas l'horloge locale injectée.
      expect(
        outcome.serverTimeMs,
        DateTime.parse('2026-06-10T10:00:00Z').millisecondsSinceEpoch,
      );
      expect(await syncMeta.getCursor('academics_evaluations:co1'), 'wm-ev');
      // Le curseur des notes n'est pas touché (split).
      expect(await syncMeta.getCursor('academics_notes:co1'), isNull);
      expect((await local.getEvaluation('ev-1'))!.syncState, SyncState.synced);
    });
  });

  group(
    '403 : garde d\'ownership serveur (cours réaffecté — DF-L point 2)',
    () {
      AcademicsDeltaPullOutcome right(
        Either<Failure, AcademicsDeltaPullOutcome> e,
      ) => e.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

      test(
        'cours réaffecté (403) : évincé localement (référence + évaluations + '
        'notes), non fatal, les autres cours du cycle continuent',
        () async {
          await insertCours('co-lost');
          await insertCours('co-ok');
          await db.insert('evaluation', {
            'id': 'ev-lost',
            'cours_id': 'co-lost',
            'type': 'INTERRO',
            'eval_date': 1,
            'max_points': 20.0,
            'poids': 1,
            'updated_at': 1,
            'sync_status': 'SYNCED',
          });
          await db.insert('note_evaluation', {
            'id': 'n-lost',
            'evaluation_id': 'ev-lost',
            'student_id': 's1',
            'points_obtenus': 12.0,
            'statut': 'NOTEE',
            'updated_at': 1,
            'sync_status': 'SYNCED',
          });

          when(
            () => api.pullEvaluations(auth, 'co-lost', null, 100),
          ).thenThrow(status(403));
          when(() => api.pullEvaluations(auth, 'co-ok', null, 100)).thenAnswer(
            (_) async => httpOk(
              const EvaluationPageDto(
                items: [
                  EvaluationDeltaDto(
                    id: 'ev-ok',
                    coursId: 'co-ok',
                    type: 'INTERRO',
                    date: '2026-06-10',
                    maxPoints: 20,
                    poids: 1,
                    serverUpdatedAt: '2026-06-10T08:00:00Z',
                  ),
                ],
                page: KeysetPageEnvelope(
                  nextWatermark: 'wm-ok',
                  hasMore: false,
                  serverTime: '2026-06-10T10:00:00Z',
                ),
              ),
            ),
          );

          final outcome = right(await repo.syncEvaluations());

          // Non fatal : le cours OK a bien été appliqué.
          expect(outcome.upserted, 1);
          expect(
            await refLocal.getCours('co-lost'),
            isNull,
            reason: 'référence évincée',
          );
          expect(
            await local.getEvaluation('ev-lost'),
            isNull,
            reason: 'évaluation évincée en cascade',
          );
          expect(
            await local.getNotesForEvaluation('ev-lost'),
            isEmpty,
            reason: 'notes évincées en cascade',
          );
          expect(await refLocal.getCours('co-ok'), isNotNull);
          // Curseur des DEUX ressources purgé pour 'co-lost' (pas seulement
          // 'evaluations' qui a 403) — sinon 'notes:co-lost' resterait un
          // curseur orphelin périmé si le cours est réaffecté en retour.
          expect(
            await syncMeta.getCursor('academics_evaluations:co-lost'),
            isNull,
          );
          expect(await syncMeta.getCursor('academics_notes:co-lost'), isNull);
        },
      );

      test(
        'cours 403 SEUL dans le cycle : outcome Right notModified, jamais Left '
        '(l\'éviction non fatale ne doit pas être comptée comme un échec)',
        () async {
          await insertCours('co-lost');

          when(
            () => api.pullEvaluations(auth, 'co-lost', null, 100),
          ).thenThrow(status(403));

          final result = await repo.syncEvaluations();

          final outcome = right(result);
          expect(outcome.notModified, isTrue);
          expect(await refLocal.getCours('co-lost'), isNull);
        },
      );
    },
  );
}

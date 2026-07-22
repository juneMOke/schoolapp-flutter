import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_cours_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/cours_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockAcademicsCoursPullApi extends Mock implements AcademicsCoursPullApi {}

void main() {
  late Database db;
  late MockAcademicsCoursPullApi api;
  late SyncMetaDao syncMeta;
  late AcademicsRefLocalDataSource refLocal;
  late AcademicsLocalDataSource academicsLocal;
  late AcademicsCoursPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockAcademicsCoursPullApi();
    syncMeta = SyncMetaDao(db);
    refLocal = AcademicsRefLocalDataSource(db);
    academicsLocal = AcademicsLocalDataSource(db);
    repo = AcademicsCoursPullRepositoryImpl(
      api: api,
      localDataSource: refLocal,
      academicsLocalDataSource: academicsLocal,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  CoursPullOutcome right(Either<Failure, CoursPullOutcome> e) =>
      e.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

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

  CoursPageDto page(
    List<CoursDeltaDto> items, {
    String? nextWatermark,
    bool hasMore = false,
    String? nextCursor,
  }) => CoursPageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-07-22T10:00:00Z',
    ),
  );

  CoursDeltaDto cours(String id, String classroomId) => CoursDeltaDto(
    id: id,
    classroomId: classroomId,
    ligneBaremeId: 'lb-1',
    serverUpdatedAt: '2026-07-22T09:00:00Z',
  );

  test(
    'bootstrap : page unique appliquée, watermark mémorisé, bootstrap OK',
    () async {
      when(() => api.pullCours(auth, null, 100)).thenAnswer(
        (_) async => httpOk(
          page([cours('co1', 'c1'), cours('co2', 'c1')], nextWatermark: 'wm'),
        ),
      );

      final outcome = right(await repo.syncCours());

      expect(outcome.upserted, 2);
      expect(outcome.bootstrapComplete, isTrue);
      expect(
        outcome.serverTimeMs,
        DateTime.parse('2026-07-22T10:00:00Z').millisecondsSinceEpoch,
      );
      expect(await syncMeta.getCursor(kAcademicsCoursResourcePrefix), 'wm');
      expect(await refLocal.getCours('co1'), isNotNull);
      expect(await refLocal.getCours('co2'), isNotNull);
    },
  );

  test(
    'multi-pages : curseur mémorisé à chaque page, watermark en fin',
    () async {
      when(() => api.pullCours(auth, null, 100)).thenAnswer(
        (_) async =>
            httpOk(page([cours('co1', 'c1')], nextCursor: 'c1', hasMore: true)),
      );
      when(() => api.pullCours(auth, 'c1', 100)).thenAnswer(
        (_) async => httpOk(page([cours('co2', 'c1')], nextWatermark: 'wm-2')),
      );

      final outcome = right(await repo.syncCours());

      expect(outcome.upserted, 2);
      expect(await syncMeta.getCursor(kAcademicsCoursResourcePrefix), 'wm-2');
      verify(() => api.pullCours(auth, null, 100)).called(1);
      verify(() => api.pullCours(auth, 'c1', 100)).called(1);
    },
  );

  test('304 → notModified, curseur conservé', () async {
    await syncMeta.setCursor(
      kAcademicsCoursResourcePrefix,
      cursor: 'wm-prev',
      syncedAt: 1,
    );
    when(() => api.pullCours(auth, 'wm-prev', 100)).thenThrow(status(304));

    final outcome = right(await repo.syncCours());

    expect(outcome.notModified, isTrue);
    expect(await syncMeta.getCursor(kAcademicsCoursResourcePrefix), 'wm-prev');
    expect(outcome.serverTimeMs, isNull);
  });

  test(
    '404 (compte non lié à un enseignant) → notModified, jamais une erreur',
    () async {
      when(() => api.pullCours(auth, null, 100)).thenThrow(status(404));

      final outcome = right(await repo.syncCours());

      expect(outcome.notModified, isTrue);
      verify(() => api.pullCours(auth, null, 100)).called(1);
    },
  );

  test('400 → curseur illisible : rebootstrap depuis null', () async {
    await syncMeta.setCursor(
      kAcademicsCoursResourcePrefix,
      cursor: 'forged',
      syncedAt: 1,
    );
    when(() => api.pullCours(auth, 'forged', 100)).thenThrow(status(400));
    when(() => api.pullCours(auth, null, 100)).thenAnswer(
      (_) async =>
          httpOk(page([cours('co1', 'c1')], nextWatermark: 'wm-fresh')),
    );

    final outcome = right(await repo.syncCours());

    expect(outcome.upserted, 1);
    expect(await syncMeta.getCursor(kAcademicsCoursResourcePrefix), 'wm-fresh');
  });

  test('échec réseau (503) → Left, le coordinateur re-tentera', () async {
    when(() => api.pullCours(auth, null, 100)).thenThrow(status(503));

    final result = await repo.syncCours();

    expect(result.isLeft(), isTrue);
  });

  group('réconciliation DF-L (cours réaffecté à un autre prof)', () {
    test(
      'cycle BOOTSTRAP complet : un cours local absent du snapshot est évincé '
      'en cascade (référence + évaluations + notes)',
      () async {
        // 'co-stale' appartenait au prof avant réaffectation : présent en
        // local, mais absent du snapshot serveur retourné par ce bootstrap.
        await refLocal.applyPulledCours([
          cours('co-stale', 'c1').toLocalRow(1),
        ]);
        await db.insert('evaluation', {
          'id': 'ev-stale',
          'cours_id': 'co-stale',
          'type': 'INTERRO',
          'eval_date': 1,
          'max_points': 20.0,
          'poids': 1,
          'updated_at': 1,
          'sync_status': 'SYNCED',
        });
        await db.insert('note_evaluation', {
          'id': 'n-stale',
          'evaluation_id': 'ev-stale',
          'student_id': 's1',
          'points_obtenus': 12.0,
          'statut': 'NOTEE',
          'updated_at': 1,
          'sync_status': 'SYNCED',
        });
        // Curseurs métier existants pour 'co-stale' — doivent être purgés,
        // sinon une réaffectation EN RETOUR reprendrait au lieu de
        // rebootstraper et perdrait silencieusement tout ce qui existait.
        await syncMeta.setCursor(
          'academics_evaluations:co-stale',
          cursor: 'wm-eval-old',
          syncedAt: 1,
        );
        await syncMeta.setCursor(
          'academics_notes:co-stale',
          cursor: 'wm-notes-old',
          syncedAt: 1,
        );

        when(() => api.pullCours(auth, null, 100)).thenAnswer(
          (_) async => httpOk(page([cours('co1', 'c1')], nextWatermark: 'wm')),
        );

        await repo.syncCours();

        expect(
          await refLocal.getCours('co-stale'),
          isNull,
          reason: 'référence évincée',
        );
        expect(
          await academicsLocal.getEvaluation('ev-stale'),
          isNull,
          reason: 'évaluation évincée en cascade',
        );
        expect(
          (await academicsLocal.getNotesForEvaluation('ev-stale')),
          isEmpty,
          reason: 'notes évincées en cascade',
        );
        expect(
          await refLocal.getCours('co1'),
          isNotNull,
          reason: 'cours du snapshot conservé',
        );
        expect(
          await syncMeta.getCursor('academics_evaluations:co-stale'),
          isNull,
          reason:
              'curseur purgé (sinon reprise périmée si réaffecté en retour)',
        );
        expect(await syncMeta.getCursor('academics_notes:co-stale'), isNull);
      },
    );

    test(
      'bootstrap MULTI-PAGES : les ids vus sur TOUTES les pages sont '
      'conservés au moment de l\'éviction (pas seulement la dernière page)',
      () async {
        // 'co-page1' n'apparaît que sur la 1ʳᵉ page — il ne doit PAS être
        // évincé même si l'éviction se décide après la dernière page.
        await refLocal.applyPulledCours([
          cours('co-page1', 'c1').toLocalRow(1),
          cours('co-page2', 'c1').toLocalRow(1),
          cours('co-stale', 'c1').toLocalRow(1),
        ]);

        when(() => api.pullCours(auth, null, 100)).thenAnswer(
          (_) async => httpOk(
            page([cours('co-page1', 'c1')], nextCursor: 'c1', hasMore: true),
          ),
        );
        when(() => api.pullCours(auth, 'c1', 100)).thenAnswer(
          (_) async =>
              httpOk(page([cours('co-page2', 'c1')], nextWatermark: 'wm-2')),
        );

        await repo.syncCours();

        expect(
          await refLocal.getCours('co-page1'),
          isNotNull,
          reason: 'vu sur la 1ʳᵉ page, pas évincé',
        );
        expect(
          await refLocal.getCours('co-page2'),
          isNotNull,
          reason: 'vu sur la 2ᵉ page, pas évincé',
        );
        expect(
          await refLocal.getCours('co-stale'),
          isNull,
          reason: 'absent des deux pages, évincé',
        );
      },
    );

    test(
      'cycle REPRIS (curseur non null) : aucune éviction — un delta ne porte '
      'que des nouveautés, pas l\'univers complet',
      () async {
        await refLocal.applyPulledCours([cours('co-old', 'c1').toLocalRow(1)]);
        await syncMeta.setCursor(
          kAcademicsCoursResourcePrefix,
          cursor: 'wm-prev',
          syncedAt: 1,
        );

        // Le delta ne renvoie qu'une nouveauté ('co-new') — 'co-old' n'a pas
        // bougé et n'apparaît donc pas dans cette page, sans que ça signifie
        // qu'il a été retiré au prof.
        when(() => api.pullCours(auth, 'wm-prev', 100)).thenAnswer(
          (_) async =>
              httpOk(page([cours('co-new', 'c1')], nextWatermark: 'wm-next')),
        );

        await repo.syncCours();

        expect(
          await refLocal.getCours('co-old'),
          isNotNull,
          reason: 'PAS évincé sur un cycle repris',
        );
        expect(await refLocal.getCours('co-new'), isNotNull);
      },
    );

    test('snapshot vide (0 cours pour ce prof) évince tout le local', () async {
      await refLocal.applyPulledCours([cours('co-old', 'c1').toLocalRow(1)]);

      when(
        () => api.pullCours(auth, null, 100),
      ).thenAnswer((_) async => httpOk(page(const [])));

      await repo.syncCours();

      expect(await refLocal.getCours('co-old'), isNull);
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_pull_models.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_pull_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockDisciplinaryPullApi extends Mock implements DisciplinaryPullApi {}

void main() {
  late Database db;
  late MockDisciplinaryPullApi api;
  late SyncMetaDao syncMeta;
  late DisciplinaryLocalDataSource local;
  late DisciplinaryPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const resource = DisciplinaryPullRepositoryImpl.resource;
  const bootstrapResource = DisciplinaryPullRepositoryImpl.bootstrapResource;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockDisciplinaryPullApi();
    syncMeta = SyncMetaDao(db);
    local = DisciplinaryLocalDataSource(db);
    repo = DisciplinaryPullRepositoryImpl(
      api: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  DisciplinaryPullOutcome right(Either<Failure, DisciplinaryPullOutcome> e) =>
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

  DisciplinaryCasePageDto page(
    List<DisciplinaryCaseDeltaDto> items, {
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => DisciplinaryCasePageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-07-18T10:00:00Z',
    ),
  );

  DisciplinaryCaseDeltaDto caseDelta(
    String id, {
    List<DisciplinaryCommentDeltaDto> comments = const [],
    String status = 'OPEN',
  }) => DisciplinaryCaseDeltaDto(
    id: id,
    studentId: 'stu-1',
    studentFirstName: 'Amina',
    studentLastName: 'Kalala',
    academicYearId: 'ay-1',
    category: 'FIGHTING',
    severity: 'SERIOUS',
    title: 'Incident',
    content: 'Bagarre',
    disciplinaryCaseDate: '2026-05-04',
    status: status,
    sanction: 'DETENTION',
    clientUpdatedAt: '2026-05-04T08:00:00.000Z',
    serverUpdatedAt: '2026-05-04T08:00:05.000Z',
    comments: comments,
  );

  test(
    'bootstrap 1 page : applique cas + commentaire, pose bootstrapComplete',
    () async {
      when(
        () => api.pullDisciplinaryCases(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          page([
            caseDelta(
              'case-1',
              comments: const [
                DisciplinaryCommentDeltaDto(
                  id: 'cm-1',
                  content: 'Convocation',
                  createdAt: '2026-05-04T09:00:00.000Z',
                ),
              ],
            ),
          ], nextWatermark: 'w1'),
        ),
      );

      final outcome = right(await repo.syncDisciplinaryCases());
      expect(outcome.upserted, 1);
      expect(outcome.bootstrapComplete, isTrue);

      final row = await local.getCase('case-1');
      expect(row, isNotNull);
      expect(row!.syncStatus, SyncState.synced.dbValue);
      expect(row.status, 'OPEN');
      expect(row.serverUpdatedAt, isNotNull);

      final comments = await local.getCommentsForCase('case-1');
      expect(comments, hasLength(1));
      expect(comments.first.syncStatus, SyncState.synced.dbValue);

      // Curseur de progression persisté (watermark de fin de cycle).
      expect(await syncMeta.getCursor(resource), 'w1');
      expect(await syncMeta.getCursor(bootstrapResource), 'DONE');
    },
  );

  test('freshness : localOnly avant pull, à jour après bootstrap', () async {
    // Avant toute synchro : poste local (pas de bootstrap).
    final before = await repo.freshness();
    expect(before.bootstrapComplete, isFalse);
    expect(before.syncedAt, isNull);

    when(
      () => api.pullDisciplinaryCases(any(), any(), any(), any(), any()),
    ).thenAnswer(
      (_) async => httpOk(page([caseDelta('case-1')], nextWatermark: 'w1')),
    );
    await repo.syncDisciplinaryCases();

    final after = await repo.freshness();
    expect(after.bootstrapComplete, isTrue);
    expect(after.syncedAt, 10000); // horloge injectée
  });

  test('304 → notModified, curseur conservé', () async {
    await syncMeta.setCursor(resource, cursor: 'c-kept', syncedAt: 1);
    when(
      () => api.pullDisciplinaryCases(any(), any(), any(), any(), any()),
    ).thenThrow(status(304));

    final outcome = right(await repo.syncDisciplinaryCases());
    expect(outcome.notModified, isTrue);
    expect(await syncMeta.getCursor(resource), 'c-kept');
  });

  test('400 curseur forgé → purge + rebootstrap depuis null', () async {
    await syncMeta.setCursor(resource, cursor: 'forged', syncedAt: 1);
    final cursors = <String?>[];
    when(
      () => api.pullDisciplinaryCases(any(), any(), any(), any(), any()),
    ).thenAnswer((inv) async {
      final sent = inv.positionalArguments[1] as String?;
      cursors.add(sent);
      if (sent == 'forged') throw status(400);
      return httpOk(page([caseDelta('case-1')], nextWatermark: 'w1'));
    });

    final outcome = right(await repo.syncDisciplinaryCases());
    expect(outcome.upserted, 1);
    // 1er essai avec le curseur forgé (400), 2e essai rebootstrap depuis null.
    expect(cursors, ['forged', null]);
    expect(await local.getCase('case-1'), isNotNull);
  });

  test('re-pull d\'un cas SYNCED : le FAIT est préservé, seul le traitement '
      'change', () async {
    // Cas déjà synchronisé, avec le vrai genre + un contenu sensible local.
    await db.insert(
      'disciplinary_cases',
      const OfflineDisciplinaryCaseRow(
        id: 'case-1',
        studentId: 'stu-1',
        studentFirstName: 'Amina',
        studentLastName: 'Kalala',
        studentGender: 'FEMALE',
        academicYearId: 'ay-1',
        disciplinaryCaseDate: '2026-05-04',
        title: 'Incident',
        content: 'Contenu local sensible',
        category: 'FIGHTING',
        severity: 'SERIOUS',
        status: 'OPEN',
        updatedAt: 5000,
        syncStatus: 'SYNCED',
      ).toMap(),
    );

    // Le delta ne porte PAS le genre (→ OTHER dans le DTO) et fait évoluer le
    // statut à RESOLVED.
    when(
      () => api.pullDisciplinaryCases(any(), any(), any(), any(), any()),
    ).thenAnswer(
      (_) async => httpOk(
        page([caseDelta('case-1', status: 'RESOLVED')], nextWatermark: 'w1'),
      ),
    );

    final outcome = right(await repo.syncDisciplinaryCases());
    expect(outcome.upserted, 1);

    final row = await local.getCase('case-1');
    // FAIT immuable préservé (genre non écrasé à OTHER, contenu non blanchi).
    expect(row!.studentGender, 'FEMALE');
    expect(row.content, 'Contenu local sensible');
    // Traitement mis à jour depuis le serveur.
    expect(row.status, 'RESOLVED');
    expect(row.syncStatus, SyncState.synced.dbValue);
    expect(row.serverUpdatedAt, isNotNull);
  });

  test('ne clobbère pas une écriture locale PENDING_SYNC', () async {
    // Cas local non synchronisé (créé hors-ligne, statut PENDING).
    await db.insert(
      'disciplinary_cases',
      const OfflineDisciplinaryCaseRow(
        id: 'case-1',
        studentId: 'stu-1',
        studentFirstName: 'Local',
        studentLastName: 'Pending',
        studentGender: 'MALE',
        academicYearId: 'ay-1',
        disciplinaryCaseDate: '2026-05-04',
        title: 'Local title',
        content: 'Local content',
        status: 'PENDING',
        updatedAt: 5000,
        syncStatus: 'PENDING_SYNC',
      ).toMap(),
    );

    when(
      () => api.pullDisciplinaryCases(any(), any(), any(), any(), any()),
    ).thenAnswer(
      (_) async => httpOk(page([caseDelta('case-1')], nextWatermark: 'w1')),
    );

    final outcome = right(await repo.syncDisciplinaryCases());
    expect(outcome.upserted, 0); // sauté

    // La version locale (gagnante) est intacte, pas écrasée par le serveur.
    final row = await local.getCase('case-1');
    expect(row!.title, 'Local title');
    expect(row.status, 'PENDING');
    expect(row.syncStatus, SyncState.pendingSync.dbValue);
  });
}

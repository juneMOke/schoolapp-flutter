import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_pull_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_pull_models.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_transfer_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockClassroomTransferPullApi extends Mock
    implements ClassroomTransferPullApi {}

void main() {
  late Database db;
  late MockClassroomTransferPullApi api;
  late SyncMetaDao syncMeta;
  late ClassroomLocalDataSource local;
  late ClassroomTransferPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const resource = ClassroomTransferPullRepositoryImpl.resource;
  const bootstrapResource =
      ClassroomTransferPullRepositoryImpl.bootstrapResource;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockClassroomTransferPullApi();
    syncMeta = SyncMetaDao(db);
    local = ClassroomLocalDataSource(db);
    repo = ClassroomTransferPullRepositoryImpl(
      api: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
    // Classe destination connue localement → school_level_id résolu.
    await db.insert('ref_classrooms', {
      'id': 'c2',
      'academic_year_id': 'ay-1',
      'school_level_id': 'lvl-1',
      'name': 'B',
      'total_count': 0,
      'female_count': 0,
      'male_count': 0,
    });
  });

  tearDown(() async => db.close());

  ClassroomTransferPullOutcome right(
    Either<Failure, ClassroomTransferPullOutcome> e,
  ) => e.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

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

  ClassroomTransferPageDto page(
    List<ClassroomTransferDeltaDto> items, {
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => ClassroomTransferPageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-07-18T10:00:00Z',
    ),
  );

  ClassroomTransferDeltaDto delta(String id) => ClassroomTransferDeltaDto(
    id: id,
    studentId: 'stu-$id',
    fromClassroomId: 'c1',
    toClassroomId: 'c2',
    academicYearId: 'ay-1',
    transferredAt: '2026-05-04T08:00:00.000Z',
    serverUpdatedAt: '2026-05-04T08:00:05.000Z',
  );

  test(
    'bootstrap 1 page : applique le transfert SYNCED + bootstrapComplete',
    () async {
      when(
        () => api.pullTransfers(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(page([delta('t1')], nextWatermark: 'w1')),
      );

      final outcome = right(await repo.syncTransfers());

      expect(outcome.upserted, 1);
      expect(outcome.bootstrapComplete, isTrue);
      // Horloge SERVEUR (page.serverTime), pas l'horloge locale injectée.
      expect(
        outcome.serverTimeMs,
        DateTime.parse('2026-07-18T10:00:00Z').millisecondsSinceEpoch,
      );
      // Ligne appliquée SYNCED, school_level_id résolu depuis ref_classrooms(c2).
      final row = (await db.query('classroom_transfers')).single;
      expect(row['id'], 't1');
      expect(row['sync_status'], 'SYNCED');
      expect(row['school_level_id'], 'lvl-1');
      // Curseur = watermark de fin de cycle ; drapeau bootstrap posé.
      expect(await syncMeta.getCursor(resource), 'w1');
      expect(await syncMeta.getCursor(bootstrapResource), 'DONE');
    },
  );

  test('multi-pages : curseur persisté à chaque page', () async {
    final responses = [
      httpOk(page([delta('t1')], nextCursor: 'c-1', hasMore: true)),
      httpOk(page([delta('t2')], nextWatermark: 'w1')),
    ];
    var call = 0;
    when(
      () => api.pullTransfers(any(), any(), any(), any(), any()),
    ).thenAnswer((_) async => responses[call++]);

    final outcome = right(await repo.syncTransfers());

    expect(outcome.upserted, 2);
    expect(await syncMeta.getCursor(resource), 'w1');
    expect((await db.query('classroom_transfers')).length, 2);
  });

  test('304 → notModified, curseur conservé', () async {
    await syncMeta.setCursor(resource, cursor: 'keep', syncedAt: 1);
    when(
      () => api.pullTransfers(any(), any(), any(), any(), any()),
    ).thenThrow(status(304));

    final outcome = right(await repo.syncTransfers());

    expect(outcome.notModified, isTrue);
    expect(await syncMeta.getCursor(resource), 'keep');
    expect(outcome.serverTimeMs, isNull);
  });

  test('400 curseur forgé → purge + rebootstrap depuis le début', () async {
    await syncMeta.setCursor(resource, cursor: 'forged', syncedAt: 1);
    var call = 0;
    when(
      () => api.pullTransfers(any(), any(), any(), any(), any()),
    ).thenAnswer((invocation) async {
      // 1er appel (curseur 'forged') → 400 ; 2e appel (bootstrap, curseur null) → page.
      if (call++ == 0) throw status(400);
      return httpOk(page([delta('t1')], nextWatermark: 'w1'));
    });

    final outcome = right(await repo.syncTransfers());

    expect(outcome.upserted, 1);
    expect(await syncMeta.getCursor(resource), 'w1');
  });

  test('page incohérente (hasMore sans curseur) → Left', () async {
    when(
      () => api.pullTransfers(any(), any(), any(), any(), any()),
    ).thenAnswer((_) async => httpOk(page([delta('t1')], hasMore: true)));

    final result = await repo.syncTransfers();
    expect(result, isA<Left<Failure, dynamic>>());
  });

  test(
    'classe destination inconnue localement → school_level_id vide',
    () async {
      when(
        () => api.pullTransfers(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          page([
            const ClassroomTransferDeltaDto(
              id: 't9',
              studentId: 'stu-9',
              fromClassroomId: 'cX',
              toClassroomId: 'cY', // pas en base
              academicYearId: 'ay-1',
              transferredAt: '2026-05-04T08:00:00.000Z',
              serverUpdatedAt: '2026-05-04T08:00:05.000Z',
            ),
          ], nextWatermark: 'w1'),
        ),
      );

      right(await repo.syncTransfers());
      final row = (await db.query(
        'classroom_transfers',
        where: 'id = ?',
        whereArgs: ['t9'],
      )).single;
      expect(row['school_level_id'], '');
    },
  );
}

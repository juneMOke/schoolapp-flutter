import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_pull_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_pull_models.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockClassroomPullApi extends Mock implements ClassroomPullApi {}

void main() {
  late Database db;
  late MockClassroomPullApi api;
  late SyncMetaDao syncMeta;
  late ClassroomLocalDataSource local;
  late ClassroomPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const resource = ClassroomPullRepositoryImpl.resource;
  const yearId = 'ay-1';

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockClassroomPullApi();
    syncMeta = SyncMetaDao(db);
    local = ClassroomLocalDataSource(db);
    repo = ClassroomPullRepositoryImpl(
      api: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  ClassroomPullOutcome right(Either<Failure, ClassroomPullOutcome> e) =>
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

  ClassroomPageDto page(
    List<ClassroomDto> items, {
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => ClassroomPageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-07-27T10:00:00Z',
    ),
  );

  ClassroomDto classroom(String id) => ClassroomDto(
    id: id,
    academicYearId: yearId,
    name: 'Classe $id',
    totalCount: 10,
    femaleCount: 5,
    maleCount: 5,
  );

  test('bootstrap 1 page : applique la classe, curseur = watermark', () async {
    when(() => api.pullClassrooms(any(), any(), any(), any())).thenAnswer(
      (_) async => httpOk(page([classroom('c1')], nextWatermark: 'w1')),
    );

    final outcome = right(await repo.syncClassrooms(academicYearId: yearId));

    expect(outcome.upserted, 1);
    expect(
      outcome.serverTimeMs,
      DateTime.parse('2026-07-27T10:00:00Z').millisecondsSinceEpoch,
    );
    expect((await db.query('ref_classrooms')).single['id'], 'c1');
    expect(await syncMeta.getCursor(resource), 'w1');
  });

  test('multi-pages : curseur persisté à chaque page', () async {
    final responses = [
      httpOk(page([classroom('c1')], nextCursor: 'c-1', hasMore: true)),
      httpOk(page([classroom('c2')], nextWatermark: 'w1')),
    ];
    var call = 0;
    when(
      () => api.pullClassrooms(any(), any(), any(), any()),
    ).thenAnswer((_) async => responses[call++]);

    final outcome = right(await repo.syncClassrooms(academicYearId: yearId));

    expect(outcome.upserted, 2);
    expect(await syncMeta.getCursor(resource), 'w1');
    expect((await db.query('ref_classrooms')).length, 2);
  });

  test('304 → notModified, curseur conservé', () async {
    await syncMeta.setCursor(resource, cursor: 'keep', syncedAt: 1);
    when(
      () => api.pullClassrooms(any(), any(), any(), any()),
    ).thenThrow(status(304));

    final outcome = right(await repo.syncClassrooms(academicYearId: yearId));

    expect(outcome.notModified, isTrue);
    expect(await syncMeta.getCursor(resource), 'keep');
    expect(outcome.serverTimeMs, isNull);
  });

  test('400 curseur forgé → purge + rebootstrap depuis le début', () async {
    await syncMeta.setCursor(resource, cursor: 'forged', syncedAt: 1);
    var call = 0;
    when(() => api.pullClassrooms(any(), any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      if (call++ == 0) throw status(400);
      return httpOk(page([classroom('c1')], nextWatermark: 'w1'));
    });

    final outcome = right(await repo.syncClassrooms(academicYearId: yearId));

    expect(outcome.upserted, 1);
    expect(await syncMeta.getCursor(resource), 'w1');
  });

  test('page incohérente (hasMore sans curseur) → Left', () async {
    when(
      () => api.pullClassrooms(any(), any(), any(), any()),
    ).thenAnswer((_) async => httpOk(page([classroom('c1')], hasMore: true)));

    final result = await repo.syncClassrooms(academicYearId: yearId);
    expect(result, isA<Left<Failure, dynamic>>());
  });

  test(
    'page incohérente (curseur qui n\'avance pas) → Left (anti-boucle)',
    () async {
      final responses = [
        httpOk(page([classroom('c1')], nextCursor: 'c-1', hasMore: true)),
        // Le serveur renvoie le MÊME curseur que celui envoyé : keyset qui
        // n'avance pas → boucle infinie potentielle, doit être détecté.
        httpOk(page([classroom('c2')], nextCursor: 'c-1', hasMore: true)),
      ];
      var call = 0;
      when(
        () => api.pullClassrooms(any(), any(), any(), any()),
      ).thenAnswer((_) async => responses[call++]);

      final result = await repo.syncClassrooms(academicYearId: yearId);
      expect(result, isA<Left<Failure, dynamic>>());
    },
  );
}

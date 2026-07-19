import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_api.dart';
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
  late AcademicsRefLocalDataSource local;
  late AcademicsCoursPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const year = 'ay-1';

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockAcademicsCoursPullApi();
    syncMeta = SyncMetaDao(db);
    local = AcademicsRefLocalDataSource(db);
    repo = AcademicsCoursPullRepositoryImpl(
      api: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  Future<void> insertClassroom(String id) => db.insert('ref_classrooms', {
    'id': id,
    'academic_year_id': year,
    'name': 'Classe $id',
  });

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
      serverTime: '2026-07-19T10:00:00Z',
    ),
  );

  CoursDeltaDto cours(String id, String classroomId) => CoursDeltaDto(
    id: id,
    classroomId: classroomId,
    ligneBaremeId: 'lb-1',
    serverUpdatedAt: '2026-07-19T09:00:00Z',
  );

  test(
    'aucune classe locale → no-op notModified, aucun appel réseau',
    () async {
      final outcome = right(await repo.syncCours(academicYearId: year));

      expect(outcome.notModified, isTrue);
      expect(outcome.upserted, 0);
      verifyNever(() => api.pullCours(any(), any(), any(), any()));
    },
  );

  test(
    'itère chaque classe avec un curseur keyset PROPRE à la classe',
    () async {
      await insertClassroom('c1');
      await insertClassroom('c2');
      when(() => api.pullCours(auth, 'c1', null, 100)).thenAnswer(
        (_) async => httpOk(page([cours('co1', 'c1')], nextWatermark: 'wm-c1')),
      );
      when(() => api.pullCours(auth, 'c2', null, 100)).thenAnswer(
        (_) async => httpOk(
          page([
            cours('co2', 'c2'),
            cours('co3', 'c2'),
          ], nextWatermark: 'wm-c2'),
        ),
      );

      final outcome = right(await repo.syncCours(academicYearId: year));

      expect(outcome.upserted, 3);
      expect(outcome.bootstrapComplete, isTrue);
      // Curseurs indépendants par classe.
      expect(await syncMeta.getCursor('academics_cours:c1'), 'wm-c1');
      expect(await syncMeta.getCursor('academics_cours:c2'), 'wm-c2');
      expect((await local.getCoursForClassroom('c2')).length, 2);
    },
  );

  test(
    '304 sur une classe → notModified pour elle, curseur conservé',
    () async {
      await insertClassroom('c1');
      await syncMeta.setCursor(
        'academics_cours:c1',
        cursor: 'wm-prev',
        syncedAt: 1,
      );
      when(
        () => api.pullCours(auth, 'c1', 'wm-prev', 100),
      ).thenThrow(status(304));

      final outcome = right(await repo.syncCours(academicYearId: year));

      expect(outcome.notModified, isTrue);
      expect(await syncMeta.getCursor('academics_cours:c1'), 'wm-prev');
    },
  );

  test(
    '400 sur une classe → rebootstrap depuis null pour cette classe',
    () async {
      await insertClassroom('c1');
      await syncMeta.setCursor(
        'academics_cours:c1',
        cursor: 'forged',
        syncedAt: 1,
      );
      when(
        () => api.pullCours(auth, 'c1', 'forged', 100),
      ).thenThrow(status(400));
      when(() => api.pullCours(auth, 'c1', null, 100)).thenAnswer(
        (_) async =>
            httpOk(page([cours('co1', 'c1')], nextWatermark: 'wm-fresh')),
      );

      final outcome = right(await repo.syncCours(academicYearId: year));

      expect(outcome.upserted, 1);
      expect(await syncMeta.getCursor('academics_cours:c1'), 'wm-fresh');
    },
  );

  test(
    'échec réseau sur une classe → Left (le coordinateur re-tentera)',
    () async {
      await insertClassroom('c1');
      when(() => api.pullCours(auth, 'c1', null, 100)).thenThrow(status(503));

      final result = await repo.syncCours(academicYearId: year);

      expect(result.isLeft(), isTrue);
    },
  );
}

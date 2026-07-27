import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_member_pull_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_pull_models.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_member_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockClassroomMemberPullApi extends Mock
    implements ClassroomMemberPullApi {}

void main() {
  late Database db;
  late MockClassroomMemberPullApi api;
  late SyncMetaDao syncMeta;
  late ClassroomLocalDataSource local;
  late ClassroomMemberPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const resource = ClassroomMemberPullRepositoryImpl.resource;
  const yearId = 'ay-1';

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockClassroomMemberPullApi();
    syncMeta = SyncMetaDao(db);
    local = ClassroomLocalDataSource(db);
    repo = ClassroomMemberPullRepositoryImpl(
      api: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  ClassroomMemberPullOutcome right(
    Either<Failure, ClassroomMemberPullOutcome> e,
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

  ClassroomMemberPageDto page(
    List<ClassroomMemberDto> items, {
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => ClassroomMemberPageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-07-27T10:00:00Z',
    ),
  );

  ClassroomMemberDto member(String id) => ClassroomMemberDto(
    id: id,
    studentId: 'stu-$id',
    classroomId: 'c1',
    academicYearId: yearId,
    studentFirstName: 'Prenom$id',
    studentLastName: 'Nom$id',
    studentGender: 'MALE',
  );

  test('bootstrap 1 page : applique le membre, curseur = watermark', () async {
    when(() => api.pullMembers(any(), any(), any(), any())).thenAnswer(
      (_) async => httpOk(page([member('m1')], nextWatermark: 'w1')),
    );

    final outcome = right(await repo.syncMembers(academicYearId: yearId));

    expect(outcome.upserted, 1);
    expect(
      outcome.serverTimeMs,
      DateTime.parse('2026-07-27T10:00:00Z').millisecondsSinceEpoch,
    );
    expect((await db.query('ref_classroom_members')).single['id'], 'm1');
    expect(await syncMeta.getCursor(resource), 'w1');
  });

  test('multi-pages : curseur persisté à chaque page', () async {
    final responses = [
      httpOk(page([member('m1')], nextCursor: 'c-1', hasMore: true)),
      httpOk(page([member('m2')], nextWatermark: 'w1')),
    ];
    var call = 0;
    when(
      () => api.pullMembers(any(), any(), any(), any()),
    ).thenAnswer((_) async => responses[call++]);

    final outcome = right(await repo.syncMembers(academicYearId: yearId));

    expect(outcome.upserted, 2);
    expect(await syncMeta.getCursor(resource), 'w1');
    expect((await db.query('ref_classroom_members')).length, 2);
  });

  test('304 → notModified, curseur conservé', () async {
    await syncMeta.setCursor(resource, cursor: 'keep', syncedAt: 1);
    when(
      () => api.pullMembers(any(), any(), any(), any()),
    ).thenThrow(status(304));

    final outcome = right(await repo.syncMembers(academicYearId: yearId));

    expect(outcome.notModified, isTrue);
    expect(await syncMeta.getCursor(resource), 'keep');
    expect(outcome.serverTimeMs, isNull);
  });

  test('400 curseur forgé → purge + rebootstrap depuis le début', () async {
    await syncMeta.setCursor(resource, cursor: 'forged', syncedAt: 1);
    var call = 0;
    when(() => api.pullMembers(any(), any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      if (call++ == 0) throw status(400);
      return httpOk(page([member('m1')], nextWatermark: 'w1'));
    });

    final outcome = right(await repo.syncMembers(academicYearId: yearId));

    expect(outcome.upserted, 1);
    expect(await syncMeta.getCursor(resource), 'w1');
  });

  test('page incohérente (hasMore sans curseur) → Left', () async {
    when(
      () => api.pullMembers(any(), any(), any(), any()),
    ).thenAnswer((_) async => httpOk(page([member('m1')], hasMore: true)));

    final result = await repo.syncMembers(academicYearId: yearId);
    expect(result, isA<Left<Failure, dynamic>>());
  });

  test(
    'page incohérente (curseur qui n\'avance pas) → Left (anti-boucle)',
    () async {
      final responses = [
        httpOk(page([member('m1')], nextCursor: 'c-1', hasMore: true)),
        // Le serveur renvoie le MÊME curseur que celui envoyé : keyset qui
        // n'avance pas → boucle infinie potentielle, doit être détecté.
        httpOk(page([member('m2')], nextCursor: 'c-1', hasMore: true)),
      ];
      var call = 0;
      when(
        () => api.pullMembers(any(), any(), any(), any()),
      ).thenAnswer((_) async => responses[call++]);

      final result = await repo.syncMembers(academicYearId: yearId);
      expect(result, isA<Left<Failure, dynamic>>());
    },
  );

  test('resource est indépendante du flux classrooms', () {
    expect(resource, 'classroom_members');
  });
}

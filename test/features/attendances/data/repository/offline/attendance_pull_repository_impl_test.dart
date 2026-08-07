import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_pull_models.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_pull_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/attendance_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockAttendancePullApi extends Mock implements AttendancePullApi {}

void main() {
  late Database db;
  late MockAttendancePullApi api;
  late SyncMetaDao syncMeta;
  late AttendanceLocalDataSource local;
  late AttendancePullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const resource = AttendancePullRepositoryImpl.resource;
  const bootstrapResource = AttendancePullRepositoryImpl.bootstrapResource;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockAttendancePullApi();
    syncMeta = SyncMetaDao(db);
    local = AttendanceLocalDataSource(db);
    repo = AttendancePullRepositoryImpl(
      api: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  AttendancePullOutcome right(Either<Failure, AttendancePullOutcome> e) =>
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

  AttendanceSessionPageDto page(
    List<AttendanceSessionDeltaDto> items, {
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => AttendanceSessionPageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-07-18T10:00:00Z',
    ),
  );

  AttendanceSessionDeltaDto session(
    String id, {
    String classroomId = 'c1',
    String date = '2026-05-04',
    List<AbsenceDeltaDto> absences = const [],
  }) => AttendanceSessionDeltaDto(
    id: id,
    classroomId: classroomId,
    attendanceDate: date,
    academicYearId: 'ay-1',
    expectedCount: 40,
    updatedAt: '2026-05-04T08:00:00.000Z',
    serverUpdatedAt: '2026-05-04T08:00:05.000Z',
    absences: absences,
  );

  test(
    'bootstrap 1 page : applique session + absence, pose bootstrapComplete',
    () async {
      when(
        () => api.pullAttendance(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          page([
            session(
              's-1',
              absences: const [
                AbsenceDeltaDto(
                  id: 'a-1',
                  studentId: 'stu-1',
                  studentFirstName: 'Aline',
                  studentLastName: 'M',
                  absenceReason: 'SICKNESS',
                  updatedAt: '2026-05-04T08:00:00.000Z',
                ),
              ],
            ),
          ], nextWatermark: 'w1'),
        ),
      );

      final outcome = right(await repo.syncAttendance());
      expect(outcome.upserted, 1);
      expect(outcome.bootstrapComplete, isTrue);
      // Horloge SERVEUR (page.serverTime), pas l'horloge locale injectée
      // (`now: () => 10000`) — c'est tout l'objet du changement.
      expect(
        outcome.serverTimeMs,
        DateTime.parse('2026-07-18T10:00:00Z').millisecondsSinceEpoch,
      );

      // Session + absence en base.
      final s = await local.getSession(
        classroomId: 'c1',
        dateStr: '2026-05-04',
        academicYearId: 'ay-1',
      );
      expect(s, isNotNull);
      expect(s!.expectedCount, 40);
      expect(s.syncStatus, 'SYNCED');
      final recs = await local.getDayRecords(
        classroomId: 'c1',
        dateStr: '2026-05-04',
        academicYearId: 'ay-1',
      );
      expect(recs.single.studentId, 'stu-1');

      // Curseur = watermark de fin de cycle ; drapeau bootstrap persisté.
      expect(await syncMeta.getCursor(resource), 'w1');
      expect(await syncMeta.getCursor(bootstrapResource), isNotNull);
    },
  );

  test(
    'multi-pages : progresse le curseur puis bascule sur le watermark',
    () async {
      final responses = <HttpResponse<AttendanceSessionPageDto>>[
        httpOk(page([session('s-1')], nextCursor: 'c1', hasMore: true)),
        httpOk(page([session('s-2', date: '2026-05-05')], nextWatermark: 'w2')),
      ];
      var call = 0;
      when(
        () => api.pullAttendance(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => responses[call++]);

      final outcome = right(await repo.syncAttendance());
      expect(outcome.upserted, 2);
      expect(await syncMeta.getCursor(resource), 'w2');
    },
  );

  test('304 au bootstrap : notModified, pas de crash', () async {
    when(
      () => api.pullAttendance(any(), any(), any(), any(), any()),
    ).thenThrow(status(304));

    final outcome = right(await repo.syncAttendance());
    expect(outcome.notModified, isTrue);
    // Pas de corps sur un 304 → pas de serverTime à parser : la date de
    // dernière synchro globale n'avance pas sur ce cycle (décision produit).
    expect(outcome.serverTimeMs, isNull);
  });

  test(
    '400 avec curseur mémorisé : purge le jeton et repart du bootstrap',
    () async {
      await syncMeta.setCursor(resource, cursor: 'stale', syncedAt: 1);
      var call = 0;
      when(
        () => api.pullAttendance(any(), any(), any(), any(), any()),
      ).thenAnswer((invocation) async {
        // 1er appel (curseur 'stale') → 400 ; 2e appel (bootstrap, cursor null) → OK.
        if (call++ == 0) throw status(400);
        return httpOk(page([session('s-1')], nextWatermark: 'w1'));
      });

      final outcome = right(await repo.syncAttendance());
      expect(outcome.upserted, 1);
      expect(await syncMeta.getCursor(resource), 'w1');
    },
  );
}

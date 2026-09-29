import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_pull_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_pull_handlers.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';

class _MockApi extends Mock implements StaffSyncApi {}

HttpResponse<T> _ok<T>(T data) => HttpResponse(
  data,
  Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
);

Map<String, dynamic> _page(List<Map<String, dynamic>> items) => {
  'items': items,
  'hasMore': false,
  'nextWatermark': 'w1',
  'serverTime': '2026-09-29T08:00:00Z',
};

void main() {
  late Database db;
  late _MockApi api;
  late SyncMetaDao meta;
  late CurrentUserContext user;
  late StaffPullRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    meta = SyncMetaDao(db);
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    repo = StaffPullRepositoryImpl(
      api: api,
      runner: KeysetPullRunner(meta, now: () => 42),
      members: StaffMemberDao(db),
      contracts: StaffContractDao(db),
      documents: StaffDocumentDao(db),
      currentUser: user,
      requiredAuth: const {},
    );
  });
  tearDown(() async => db.close());

  test('les fiches descendent et leur curseur est rangé par école', () async {
    when(() => api.pullStaffMembers(any(), any(), any())).thenAnswer(
      (_) async =>
          _ok(StaffMemberPageDto.fromJson(_page([staffMemberJson('m-1')]))),
    );

    final result = await repo.syncMembers();

    expect(result.isRight(), isTrue);
    expect(await db.query('staff_members'), hasLength(1));
    expect(await meta.getCursor('staff_members@school-1'), 'w1');
  });

  test('les contrats et les pièces ont chacun leur curseur', () async {
    when(() => api.pullStaffContracts(any(), any(), any())).thenAnswer(
      (_) async =>
          _ok(StaffContractPageDto.fromJson(_page([staffContractJson('c-1')]))),
    );
    when(() => api.pullStaffDocuments(any(), any(), any())).thenAnswer(
      (_) async =>
          _ok(StaffDocumentPageDto.fromJson(_page([staffDocumentJson('d-1')]))),
    );

    await repo.syncContracts();
    await repo.syncDocuments();

    expect(await db.query('staff_contracts'), hasLength(1));
    expect(await db.query('staff_documents'), hasLength(1));
    expect(await meta.getCursor('staff_contracts@school-1'), 'w1');
    expect(await meta.getCursor('staff_documents@school-1'), 'w1');
  });

  test('sans école courante, rien ne part', () async {
    user.set('u-1', schoolId: null);

    expect((await repo.syncMembers()).isLeft(), isTrue);
    verifyNever(() => api.pullStaffMembers(any(), any(), any()));
  });

  group('handlers', () {
    test('un flux, un droit, une clé de plan', () {
      final handlers = [
        StaffPullHandler.members(repo),
        StaffPullHandler.contracts(repo),
        StaffPullHandler.documents(repo),
      ];

      expect(handlers.map((h) => h.requiredPermissions.single), [
        Perm.hrStaffRead,
        Perm.hrPayRead,
        Perm.hrDocumentRead,
      ]);
      expect(handlers.map((h) => planKeyOf(h.resource)), [
        SyncPlanKeys.hrStaffMembers,
        SyncPlanKeys.hrStaffContracts,
        SyncPlanKeys.hrStaffDocuments,
      ]);
      expect(handlers.every((h) => !h.isBaseline), isTrue);
      expect(handlers.every((h) => isCursorKeyPrefix(h.resource)), isTrue);
    });

    test('un 304 se lit « rien de neuf », une panne « erreur »', () async {
      when(() => api.pullStaffMembers(any(), any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 304,
          ),
        ),
      );
      expect(
        (await StaffPullHandler.members(repo).pull()).result,
        PullResult.notModified,
      );

      when(
        () => api.pullStaffDocuments(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));
      expect(
        (await StaffPullHandler.documents(repo).pull()).result,
        PullResult.error,
      );
    });
  });
}

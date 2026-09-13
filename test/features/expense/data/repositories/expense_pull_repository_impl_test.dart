import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_pull_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _MockApi extends Mock implements ExpenseSyncApi {}

Map<String, dynamic> _delta(String id) => {
  'id': id,
  'expenseNumber': 'DEP-$id',
  'typeId': 't-elec',
  'title': 'Facture $id',
  'amountInCents': 1000,
  'currency': 'USD',
  'status': 'PAID',
  'expenseDate': '2026-09-03',
  'fundingSource': 'CASH',
  'clientUpdatedAt': '2026-09-03T09:00:00Z',
  'deletedAt': null,
};

HttpResponse<ExpensePageDto> _page(
  List<String> ids, {
  bool hasMore = false,
  String? next,
  String? watermark,
}) => HttpResponse(
  ExpensePageDto.fromJson({
    'items': [for (final id in ids) _delta(id)],
    'hasMore': hasMore,
    'nextCursor': next,
    'nextWatermark': watermark,
    'serverTime': '2026-09-13T08:00:00Z',
  }),
  Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
);

DioException _http(int status) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late SyncMetaDao meta;
  late ExpensePullRepositoryImpl repo;
  late CurrentUserContext user;

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    meta = SyncMetaDao(db);
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    repo = ExpensePullRepositoryImpl(
      api: api,
      dao: ExpenseSyncDao(db),
      syncMetaDao: meta,
      currentUser: user,
      requiredAuth: const {},
      now: () => 42,
    );
  });
  tearDown(() async => db.close());

  test(
    'bootstrap : deux pages appliquées, watermark mémorisé par école',
    () async {
      when(
        () => api.pullExpenses(any(), any(that: isNull), any()),
      ).thenAnswer((_) async => _page(['a'], hasMore: true, next: 'c-1'));
      when(
        () => api.pullExpenses(any(), any(that: equals('c-1')), any()),
      ).thenAnswer((_) async => _page(['b'], watermark: 'w-1'));

      final result = await repo.syncExpenses();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (outcome) => expect(outcome.upserted, 2));
      expect(await ExpenseReadDao(db).find('b'), isNotNull);
      expect(await meta.getCursor('expenses@school-1'), 'w-1');
    },
  );

  test('304 → rien de neuf, jeton conservé', () async {
    await meta.setCursor('expenses@school-1', cursor: 'w-0', syncedAt: 1);
    when(() => api.pullExpenses(any(), any(), any())).thenThrow(_http(304));

    final result = await repo.syncExpenses();

    result.fold((f) => fail('$f'), (o) => expect(o.notModified, isTrue));
    expect(await meta.getCursor('expenses@school-1'), 'w-0');
  });

  test('400 sur un jeton mémorisé → repli au bootstrap', () async {
    await meta.setCursor('expenses@school-1', cursor: 'forgé', syncedAt: 1);
    when(
      () => api.pullExpenses(any(), any(that: equals('forgé')), any()),
    ).thenThrow(_http(400));
    when(
      () => api.pullExpenses(any(), any(that: isNull), any()),
    ).thenAnswer((_) async => _page(['a'], watermark: 'w-1'));

    final result = await repo.syncExpenses();

    expect(result.isRight(), isTrue);
    expect(await meta.getCursor('expenses@school-1'), 'w-1');
  });

  test('hasMore sans curseur neuf → échec, jamais de boucle', () async {
    when(
      () => api.pullExpenses(any(), any(), any()),
    ).thenAnswer((_) async => _page(['a'], hasMore: true, next: null));

    final result = await repo.syncExpenses();
    // La cause est épinglée : une page illisible rendrait aussi un `Left`.
    result.fold(
      (failure) => expect(failure.message, contains('incohérente')),
      (_) => fail('une page incohérente doit échouer'),
    );
  });

  test('sans école : aucun appel, le curseur ne peut pas être scopé', () async {
    user.clear();
    expect((await repo.syncExpenses()).isLeft(), isTrue);
    verifyNever(() => api.pullExpenses(any(), any(), any()));
  });
}

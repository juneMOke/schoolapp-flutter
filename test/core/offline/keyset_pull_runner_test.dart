import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../features/offline_full_db.dart';

class _Page implements KeysetPageDto<String> {
  @override
  final List<String> items;
  @override
  final KeysetPageEnvelope page;

  _Page(this.items, {bool hasMore = false, String? next, String? watermark})
    : page = KeysetPageEnvelope(
        hasMore: hasMore,
        nextCursor: next,
        nextWatermark: watermark,
        serverTime: '2026-09-29T08:00:00Z',
      );
}

DioException _http(int status) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
  ),
);

void main() {
  const key = 'staff_members@school-1';
  late Database db;
  late SyncMetaDao meta;
  late KeysetPullRunner runner;
  late List<String?> sentCursors;
  late List<String> applied;

  setUp(() async {
    db = await openFullOfflineDb();
    meta = SyncMetaDao(db);
    runner = KeysetPullRunner(meta, now: () => 42);
    sentCursors = [];
    applied = [];
  });
  tearDown(() async => db.close());

  Future<int> apply(List<String> items, int syncedAt) async {
    applied.addAll(items);
    return items.length;
  }

  Future<Object> runWith(List<Object> responses) async {
    final queue = [...responses];
    final result = await runner.run<String>(
      cursorKey: key,
      label: 'test',
      fetch: (cursor) async {
        sentCursors.add(cursor);
        final next = queue.removeAt(0);
        if (next is DioException) throw next;
        return next as _Page;
      },
      apply: apply,
    );
    return result.fold((failure) => failure, (ok) => ok);
  }

  test('parcourt les pages et mémorise le watermark de fin de cycle', () async {
    final outcome = await runWith([
      _Page(['a', 'b'], hasMore: true, next: 'c1'),
      _Page(['c'], watermark: 'w1'),
    ]);

    expect(outcome, isA<KeysetPullResult>());
    expect((outcome as KeysetPullResult).upserted, 3);
    expect(outcome.serverTimeMs, isNotNull);
    expect(sentCursors, [null, 'c1']);
    expect(applied, ['a', 'b', 'c']);
    expect(await meta.getCursor(key), 'w1');
  });

  test('un 304 garde le curseur mémorisé et ne signale rien de neuf', () async {
    await meta.setCursor(key, cursor: 'w0', syncedAt: 1);

    final outcome = await runWith([_http(304)]);

    expect((outcome as KeysetPullResult).notModified, isTrue);
    expect(sentCursors, ['w0']);
    expect(await meta.getCursor(key), 'w0');
  });

  test('un curseur rejeté (400) repart une fois du début', () async {
    await meta.setCursor(key, cursor: 'forgé', syncedAt: 1);

    final outcome = await runWith([
      _http(400),
      _Page(['a'], watermark: 'w1'),
    ]);

    expect((outcome as KeysetPullResult).upserted, 1);
    expect(sentCursors, ['forgé', null]);
    expect(await meta.getCursor(key), 'w1');
  });

  test('hasMore sans curseur neuf est refusé au lieu de boucler', () async {
    final outcome = await runWith([
      _Page(['a'], hasMore: true, next: 'c1'),
      _Page(['b'], hasMore: true, next: 'c1'),
    ]);

    expect(outcome, isNot(isA<KeysetPullResult>()));
    // La première page, appliquée, reste acquise pour la reprise.
    expect(await meta.getCursor(key), 'c1');
  });

  test('une panne serveur est un échec, sans repli', () async {
    final outcome = await runWith([_http(503)]);

    expect(outcome, isNot(isA<KeysetPullResult>()));
    expect(sentCursors, [null]);
  });
}

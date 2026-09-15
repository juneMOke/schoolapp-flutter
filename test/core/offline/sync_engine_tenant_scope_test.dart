import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_database.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'offline_full_test_db.dart';

class _Online implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

class _Handler implements OutboxSyncHandler {
  _Handler({this.onDispatch});

  final void Function()? onDispatch;
  final List<String> dispatched = [];

  @override
  String get aggregateType => 'PAYMENT';

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    dispatched.add(entry.id);
    onDispatch?.call();
    return const OutboxDispatchResult.acked();
  }
}

OutboxEntry _entry(String id, int createdAt) => OutboxEntry(
  id: id,
  aggregateType: 'PAYMENT',
  aggregateId: 'agg-$id',
  operation: OutboxOperation.create,
  payload: '{}',
  createdAt: createdAt,
);

/// Un lot de l'outbox est lié à l'école attachée à son départ
/// (MULTI_ECOLE_PLAN.md §10.1).
void main() {
  late Database schoolA;
  late Database schoolB;
  late TenantDatabase tenant;

  setUp(() async {
    schoolA = await openFullOfflineDb();
    schoolB = await openFullOfflineDb();
    tenant = TenantDatabase()..attach('school-a', schoolA);
    await OutboxDao(schoolA).enqueue(_entry('e1', 1));
    await OutboxDao(schoolA).enqueue(_entry('e2', 2));
  });

  tearDown(() async {
    await schoolA.close();
    await schoolB.close();
  });

  SyncEngine engine(_Handler handler) => SyncEngine(
    outbox: OutboxDao(tenant),
    connectivity: _Online(),
    scope: tenant,
    now: () => 100000,
  )..registerHandler(handler);

  test('sans bascule, le lot part en entier', () async {
    final handler = _Handler();

    final report = await engine(handler).flush();

    expect(handler.dispatched, ['e1', 'e2']);
    expect(report.acked, 2);
  });

  test('l école change pendant le lot : rien n est marqué chez B, la suite '
      'du lot ne part pas, et les écritures de A attendent intactes', () async {
    final handler = _Handler(
      onDispatch: () {
        // A se déconnecte et B se connecte pendant que la requête de A était
        // en vol.
        tenant.detach();
        tenant.attach('school-b', schoolB);
      },
    );

    final report = await engine(handler).flush();

    expect(handler.dispatched, ['e1']);
    expect(report.acked, 0);
    expect(await schoolB.query('outbox'), isEmpty);
    final left = await OutboxDao(schoolA).pendingReady(100000);
    expect(left.map((e) => e.id), ['e1', 'e2']);
    // Ni tentative consommée, ni poison : elles ne sont pas en faute.
    expect(left.every((e) => e.attempts == 0), isTrue);
    expect(left.every((e) => e.status == OutboxStatus.pending), isTrue);
  });

  test('le moteur reste utilisable après un lot périmé', () async {
    var switched = false;
    final handler = _Handler(
      onDispatch: () {
        if (switched) return;
        switched = true;
        tenant.attach('school-b', schoolB);
      },
    );
    final sync = engine(handler);
    await sync.flush();
    await OutboxDao(schoolB).enqueue(_entry('b1', 3));

    final report = await sync.flush();

    expect(report.acked, 1);
    expect(handler.dispatched.last, 'b1');
  });
}

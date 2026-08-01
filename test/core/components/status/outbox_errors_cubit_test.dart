import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

import '../../offline/offline_test_db.dart';

/// Connectivité toujours en ligne (le flush n'est pas le sujet ici).
class _OnlineConnectivity implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Handler scriptable : compte les dispatches et rend l'issue demandée.
class _ScriptedHandler implements OutboxSyncHandler {
  @override
  final String aggregateType;
  final OutboxDispatchResult result;
  int dispatched = 0;

  _ScriptedHandler(this.aggregateType, this.result);

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    dispatched++;
    return result;
  }
}

void main() {
  late Database db;
  late OutboxDao dao;
  late SyncEngine engine;

  OutboxEntry entry({required String id, String type = 'PAYMENT'}) =>
      OutboxEntry(
        id: id,
        aggregateType: type,
        aggregateId: 'agg-$id',
        operation: OutboxOperation.create,
        payload: '{}',
        createdAt: 1000,
      );

  setUp(() async {
    db = await openInMemoryOfflineDb();
    dao = OutboxDao(db);
    engine = SyncEngine(outbox: dao, connectivity: _OnlineConnectivity());
  });

  tearDown(() async => db.close());

  test('load ne remonte que les entrées terminales', () async {
    await dao.enqueue(entry(id: 'ok'));
    await dao.enqueue(entry(id: 'ko'));
    await dao.markSyncError('ko', 'rejet serveur');

    final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
    await cubit.load();

    expect(cubit.state.status, OutboxErrorsStatus.loaded);
    expect(cubit.state.entries.map((e) => e.id), ['ko']);
    expect(cubit.state.entries.single.lastError, 'rejet serveur');
    await cubit.close();
  });

  test('retry remet en file et repousse : l\'entrée quitte la liste', () async {
    final handler = _ScriptedHandler(
      'PAYMENT',
      const OutboxDispatchResult.acked(),
    );
    engine.registerHandler(handler);
    await dao.enqueue(entry(id: 'p1'));
    await dao.markSyncError('p1', 'course concurrente');

    final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
    await cubit.load();
    expect(cubit.state.entries, hasLength(1));

    await cubit.retry('p1');

    // Le rejeu est passé par le handler (idempotence honorée serveur), puis
    // l'entrée a été acquittée et purgée : plus rien en erreur.
    expect(handler.dispatched, 1);
    expect(cubit.state.entries, isEmpty);
    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.busy, isFalse);
    await cubit.close();
  });

  test('un rejeu qui échoue de nouveau laisse l\'entrée visible', () async {
    engine.registerHandler(
      _ScriptedHandler(
        'PAYMENT',
        const OutboxDispatchResult.failed('rejet 422'),
      ),
    );
    await dao.enqueue(entry(id: 'p1'));
    await dao.markSyncError('p1', 'rejet initial');

    final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
    await cubit.load();
    await cubit.retry('p1');

    expect(cubit.state.entries, hasLength(1));
    expect(cubit.state.entries.single.lastError, 'rejet 422');
    await cubit.close();
  });

  test('retryAll remet en file toutes les entrées affichées', () async {
    final handler = _ScriptedHandler(
      'PAYMENT',
      const OutboxDispatchResult.acked(),
    );
    engine.registerHandler(handler);
    for (final id in ['a', 'b', 'c']) {
      await dao.enqueue(entry(id: id));
      await dao.markSyncError(id, 'rejet');
    }

    final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
    await cubit.load();
    await cubit.retryAll();

    expect(handler.dispatched, 3);
    expect(cubit.state.entries, isEmpty);
    await cubit.close();
  });

  test('ATTENDANCE : le rejeu du payload gelé est refusé', () async {
    final handler = _ScriptedHandler(
      'ATTENDANCE',
      const OutboxDispatchResult.acked(),
    );
    engine.registerHandler(handler);
    await dao.enqueue(entry(id: 'a1', type: 'ATTENDANCE'));
    await dao.markSyncError('a1', 'rejet');

    final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
    await cubit.load();
    await cubit.retry('a1');

    // Rien n'est parti et l'entrée reste visible : republier la photo gelée des
    // absences ferait SUPPRIMER serveur celles ajoutées depuis.
    expect(handler.dispatched, 0);
    expect(cubit.state.entries, hasLength(1));
    expect(await dao.errorCount(), 1);
    await cubit.close();
  });

  test('retryAll saute ATTENDANCE et rejoue le reste', () async {
    final payments = _ScriptedHandler(
      'PAYMENT',
      const OutboxDispatchResult.acked(),
    );
    final attendance = _ScriptedHandler(
      'ATTENDANCE',
      const OutboxDispatchResult.acked(),
    );
    engine.registerHandler(payments);
    engine.registerHandler(attendance);
    await dao.enqueue(entry(id: 'p1'));
    await dao.enqueue(entry(id: 'a1', type: 'ATTENDANCE'));
    await dao.markSyncError('p1', 'rejet');
    await dao.markSyncError('a1', 'rejet');

    final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
    await cubit.load();
    await cubit.retryAll();

    expect(payments.dispatched, 1);
    expect(attendance.dispatched, 0);
    expect(cubit.state.entries.map((e) => e.id), ['a1']);
    await cubit.close();
  });
}

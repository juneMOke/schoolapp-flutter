import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';

class _MockOutboxDao extends Mock implements OutboxDao {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockSyncMetaDao extends Mock implements SyncMetaDao {}

const _kLastSync = '__global_last_sync__';

/// La date de dernière synchro est celle de l'ÉCOLE depuis l'éclatement par
/// école (MULTI_ECOLE_PLAN.md §10.2) : elle part avec la session, et la
/// suivante relit celle de l'école qu'elle attache.
void main() {
  late _MockOutboxDao outbox;
  late _MockConnectivity connectivity;
  late _MockSyncEngine syncEngine;
  late _MockSyncMetaDao syncMetaDao;
  late StreamController<bool> status;

  setUp(() {
    outbox = _MockOutboxDao();
    connectivity = _MockConnectivity();
    syncEngine = _MockSyncEngine();
    syncMetaDao = _MockSyncMetaDao();
    status = StreamController<bool>.broadcast();
    when(() => syncEngine.addFlushCompleteListener(any())).thenReturn(() {});
    when(() => connectivity.onStatusChange).thenAnswer((_) => status.stream);
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    when(() => outbox.pendingCount()).thenAnswer((_) async => 0);
    when(() => outbox.errorCount()).thenAnswer((_) async => 0);
    when(() => outbox.heldCount()).thenAnswer((_) async => 0);
    when(() => syncEngine.isFlushing).thenReturn(false);
    when(
      () => syncMetaDao.setCursor(
        any(),
        cursor: any(named: 'cursor'),
        syncedAt: any(named: 'syncedAt'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => status.close());

  test('effacée à la fermeture, puis relue — même PLUS ANCIENNE — dans '
      'l école suivante', () async {
    when(
      () => syncMetaDao.getSyncedAt(_kLastSync),
    ).thenAnswer((_) async => 1000);
    final cubit = SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      syncMetaDao: syncMetaDao,
    );
    await pumpEventQueue();
    expect(cubit.state.lastSyncAtMs, 1000);

    cubit.onSessionClosed();
    await pumpEventQueue();
    expect(cubit.state.lastSyncAtMs, isNull);

    // L'école B s'est synchronisée AVANT l'école A : la date ne fait que
    // monter au sein d'une école, pas d'une école à l'autre.
    when(
      () => syncMetaDao.getSyncedAt(_kLastSync),
    ).thenAnswer((_) async => 500);
    await cubit.syncOnLogin();
    await pumpEventQueue();
    expect(cubit.state.lastSyncAtMs, 500);

    await cubit.close();
  });
}

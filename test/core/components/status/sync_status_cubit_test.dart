import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

class MockOutboxDao extends Mock implements OutboxDao {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late MockOutboxDao outbox;
  late MockConnectivityService connectivity;
  late MockSyncEngine syncEngine;
  late StreamController<bool> statusController;

  setUp(() {
    outbox = MockOutboxDao();
    connectivity = MockConnectivityService();
    syncEngine = MockSyncEngine();
    statusController = StreamController<bool>.broadcast();

    // Valeurs « nominales » (online, outbox vide, pas de flush) surchargées
    // au besoin dans chaque test.
    when(
      () => connectivity.onStatusChange,
    ).thenAnswer((_) => statusController.stream);
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(() => outbox.pendingCount()).thenAnswer((_) async => 0);
    when(() => outbox.errorCount()).thenAnswer((_) async => 0);
    when(() => syncEngine.isFlushing).thenReturn(false);
    when(
      () => syncEngine.flush(),
    ).thenAnswer((_) async => const SyncFlushReport());
  });

  tearDown(() async {
    await statusController.close();
  });

  SyncStatusCubit build() => SyncStatusCubit(
    outbox: outbox,
    connectivity: connectivity,
    syncEngine: syncEngine,
  );

  test('online + outbox vide → synced', () async {
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, SyncStatus.synced);
    await cubit.close();
  });

  test('hors-ligne → offline', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, SyncStatus.offline);
    await cubit.close();
  });

  test('file d\'attente non vide → pendingUpload', () async {
    when(() => outbox.pendingCount()).thenAnswer((_) async => 3);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, SyncStatus.pendingUpload);
    await cubit.close();
  });

  test(
    'erreur outbox prioritaire sur file d\'attente → syncConflict',
    () async {
      when(() => outbox.errorCount()).thenAnswer((_) async => 1);
      when(() => outbox.pendingCount()).thenAnswer((_) async => 5);
      final cubit = build();
      await pumpEventQueue();
      expect(cubit.state, SyncStatus.syncConflict);
      await cubit.close();
    },
  );

  test('flush en cours prioritaire → syncing', () async {
    when(() => syncEngine.isFlushing).thenReturn(true);
    when(() => outbox.pendingCount()).thenAnswer((_) async => 2);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, SyncStatus.syncing);
    await cubit.close();
  });

  test('passage à online déclenche un flush opportuniste', () async {
    final cubit = build();
    await pumpEventQueue();
    statusController.add(true);
    await pumpEventQueue();
    verify(() => syncEngine.flush()).called(1);
    await cubit.close();
  });

  test('passage à offline → offline sans flush', () async {
    final cubit = build();
    await pumpEventQueue();
    statusController.add(false);
    await pumpEventQueue();
    expect(cubit.state, SyncStatus.offline);
    verifyNever(() => syncEngine.flush());
    await cubit.close();
  });

  test('notifyLocalWrite rafraîchit puis pousse', () async {
    when(() => outbox.pendingCount()).thenAnswer((_) async => 1);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, SyncStatus.pendingUpload);
    await cubit.notifyLocalWrite();
    await pumpEventQueue();
    verify(() => syncEngine.flush()).called(1);
    expect(cubit.state, SyncStatus.pendingUpload);
    await cubit.close();
  });

  test('défensif : isOnline qui lève ne casse pas (reste synced)', () async {
    when(() => connectivity.isOnline()).thenThrow(Exception('no plugin'));
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, SyncStatus.synced);
    await cubit.close();
  });

  test('défensif : erreur du flux connectivité est absorbée', () async {
    final cubit = build();
    await pumpEventQueue();
    statusController.addError(Exception('boom'));
    await pumpEventQueue();
    // Ne lève pas ; l'état reste cohérent.
    expect(cubit.state, SyncStatus.synced);
    await cubit.close();
  });
}

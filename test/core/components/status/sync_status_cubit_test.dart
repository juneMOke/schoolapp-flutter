import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

class MockOutboxDao extends Mock implements OutboxDao {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockPullCoordinator extends Mock implements PullCoordinator {}

class MockCredentialsProbe extends Mock implements SessionCredentialsProbe {}

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

  test('retour online : déclenche flush PUIS pull delta', () async {
    final pull = MockPullCoordinator();
    when(() => pull.pullAll()).thenAnswer((_) async => const PullRunReport());
    final cubit = SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      pullCoordinator: pull,
    );
    await pumpEventQueue();
    statusController.add(true);
    await pumpEventQueue();
    verify(() => syncEngine.flush()).called(1);
    verify(() => pull.pullAll()).called(1);
    await cubit.close();
  });

  test('notifyLocalWrite : pousse mais ne tire PAS (aucun pull)', () async {
    final pull = MockPullCoordinator();
    when(() => pull.pullAll()).thenAnswer((_) async => const PullRunReport());
    final cubit = SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      pullCoordinator: pull,
    );
    await pumpEventQueue();
    await cubit.notifyLocalWrite();
    await pumpEventQueue();
    verify(() => syncEngine.flush()).called(1);
    verifyNever(() => pull.pullAll());
    await cubit.close();
  });

  group('gate crédentiels (V1.1 — session offline sans jetons)', () {
    late MockCredentialsProbe probe;

    setUp(() {
      probe = MockCredentialsProbe();
    });

    SyncStatusCubit buildGated({MockPullCoordinator? pull}) => SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      pullCoordinator: pull,
      credentialsProbe: probe,
    );

    test(
      'sans jetons + écritures en attente → authRequired, AUCUN flush ni pull',
      () async {
        when(() => probe.canAuthenticate()).thenAnswer((_) async => false);
        when(() => outbox.pendingCount()).thenAnswer((_) async => 2);
        final pull = MockPullCoordinator();
        when(
          () => pull.pullAll(),
        ).thenAnswer((_) async => const PullRunReport());

        final cubit = buildGated(pull: pull);
        await pumpEventQueue();
        statusController.add(true); // retour réseau
        await pumpEventQueue();

        expect(cubit.state, SyncStatus.authRequired);
        // Zéro 401, zéro `attempt` consommé : rien n'est tenté.
        verifyNever(() => syncEngine.flush());
        verifyNever(() => pull.pullAll());
        await cubit.close();
      },
    );

    test(
      'sans jetons + notifyLocalWrite → authRequired, AUCUN flush',
      () async {
        when(() => probe.canAuthenticate()).thenAnswer((_) async => false);
        when(() => outbox.pendingCount()).thenAnswer((_) async => 1);

        final cubit = buildGated();
        await pumpEventQueue();
        await cubit.notifyLocalWrite();
        await pumpEventQueue();

        expect(cubit.state, SyncStatus.authRequired);
        verifyNever(() => syncEngine.flush());
        await cubit.close();
      },
    );

    test(
      'sans jetons mais outbox vide → synced (pas de faux signal)',
      () async {
        when(() => probe.canAuthenticate()).thenAnswer((_) async => false);
        final cubit = buildGated();
        await pumpEventQueue();
        expect(cubit.state, SyncStatus.synced);
        await cubit.close();
      },
    );

    test('jetons présents → cycle normal (flush au reconnect)', () async {
      when(() => probe.canAuthenticate()).thenAnswer((_) async => true);
      when(() => outbox.pendingCount()).thenAnswer((_) async => 2);

      final cubit = buildGated();
      await pumpEventQueue();
      statusController.add(true);
      await pumpEventQueue();

      verify(() => syncEngine.flush()).called(1);
      await cubit.close();
    });

    test('sonde défaillante → ne bloque pas la synchro', () async {
      when(() => probe.canAuthenticate()).thenThrow(Exception('storage'));
      when(() => outbox.pendingCount()).thenAnswer((_) async => 1);

      final cubit = buildGated();
      await pumpEventQueue();
      statusController.add(true);
      await pumpEventQueue();

      verify(() => syncEngine.flush()).called(1);
      await cubit.close();
    });
  });
}

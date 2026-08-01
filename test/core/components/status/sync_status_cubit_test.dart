import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/session_reauthenticator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';

class MockOutboxDao extends Mock implements OutboxDao {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockPullCoordinator extends Mock implements PullCoordinator {}

class MockCredentialsProbe extends Mock implements SessionCredentialsProbe {}

class MockReauthenticator extends Mock implements SessionReauthenticator {}

class MockSyncMetaDao extends Mock implements SyncMetaDao {}

void main() {
  late MockOutboxDao outbox;
  late MockConnectivityService connectivity;
  late MockSyncEngine syncEngine;
  late MockSyncMetaDao syncMetaDao;
  late StreamController<bool> statusController;

  setUp(() {
    outbox = MockOutboxDao();
    connectivity = MockConnectivityService();
    syncEngine = MockSyncEngine();
    // Le cubit s'abonne à la fin de flush : un flush déclenché AILLEURS (les
    // repositories flushent en direct après chaque écriture) doit le faire
    // recalculer son état, sinon la pastille reste figée sur `syncing` et
    // masque le conflit qui vient d'apparaître.
    when(() => syncEngine.addFlushCompleteListener(any())).thenReturn(() {});
    syncMetaDao = MockSyncMetaDao();
    statusController = StreamController<bool>.broadcast();

    // Valeurs « nominales » (online, outbox vide, pas de flush, jamais
    // synchronisé) surchargées au besoin dans chaque test.
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
    when(() => syncMetaDao.getSyncedAt(any())).thenAnswer((_) async => null);
    when(
      () => syncMetaDao.setCursor(
        any(),
        cursor: any(named: 'cursor'),
        syncedAt: any(named: 'syncedAt'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await statusController.close();
  });

  SyncStatusCubit build() => SyncStatusCubit(
    outbox: outbox,
    connectivity: connectivity,
    syncEngine: syncEngine,
    syncMetaDao: syncMetaDao,
  );

  test('online + outbox vide → synced', () async {
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state.status, SyncStatus.synced);
    await cubit.close();
  });

  test('hors-ligne → offline', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state.status, SyncStatus.offline);
    await cubit.close();
  });

  test('file d\'attente non vide → pendingUpload', () async {
    when(() => outbox.pendingCount()).thenAnswer((_) async => 3);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state.status, SyncStatus.pendingUpload);
    await cubit.close();
  });

  test(
    'erreur outbox prioritaire sur file d\'attente → syncConflict',
    () async {
      when(() => outbox.errorCount()).thenAnswer((_) async => 1);
      when(() => outbox.pendingCount()).thenAnswer((_) async => 5);
      final cubit = build();
      await pumpEventQueue();
      expect(cubit.state.status, SyncStatus.syncConflict);
      await cubit.close();
    },
  );

  test('flush en cours prioritaire → syncing', () async {
    when(() => syncEngine.isFlushing).thenReturn(true);
    when(() => outbox.pendingCount()).thenAnswer((_) async => 2);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state.status, SyncStatus.syncing);
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
    expect(cubit.state.status, SyncStatus.offline);
    verifyNever(() => syncEngine.flush());
    await cubit.close();
  });

  test('notifyLocalWrite rafraîchit puis pousse', () async {
    when(() => outbox.pendingCount()).thenAnswer((_) async => 1);
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state.status, SyncStatus.pendingUpload);
    await cubit.notifyLocalWrite();
    await pumpEventQueue();
    verify(() => syncEngine.flush()).called(1);
    expect(cubit.state.status, SyncStatus.pendingUpload);
    await cubit.close();
  });

  test('défensif : isOnline qui lève ne casse pas (reste synced)', () async {
    when(() => connectivity.isOnline()).thenThrow(Exception('no plugin'));
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state.status, SyncStatus.synced);
    await cubit.close();
  });

  test('défensif : erreur du flux connectivité est absorbée', () async {
    final cubit = build();
    await pumpEventQueue();
    statusController.addError(Exception('boom'));
    await pumpEventQueue();
    // Ne lève pas ; l'état reste cohérent.
    expect(cubit.state.status, SyncStatus.synced);
    await cubit.close();
  });

  test('retour online : déclenche flush PUIS pull delta', () async {
    final pull = MockPullCoordinator();
    when(() => pull.pullAll()).thenAnswer((_) async => const PullRunReport());
    final cubit = SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      syncMetaDao: syncMetaDao,
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
      syncMetaDao: syncMetaDao,
      pullCoordinator: pull,
    );
    await pumpEventQueue();
    await cubit.notifyLocalWrite();
    await pumpEventQueue();
    verify(() => syncEngine.flush()).called(1);
    verifyNever(() => pull.pullAll());
    await cubit.close();
  });

  group('dernière synchro (heure serveur)', () {
    test('hydrate lastSyncAtMs persisté au démarrage', () async {
      when(
        () => syncMetaDao.getSyncedAt('__global_last_sync__'),
      ).thenAnswer((_) async => 1000);
      final cubit = build();
      await pumpEventQueue();
      expect(cubit.state.lastSyncAtMs, 1000);
      await cubit.close();
    });

    test('un pull avec serverTime avance et persiste lastSyncAtMs', () async {
      final pull = MockPullCoordinator();
      when(() => pull.pullAll()).thenAnswer(
        (_) async => const PullRunReport(updated: 1, latestServerTimeMs: 5000),
      );
      final cubit = SyncStatusCubit(
        outbox: outbox,
        connectivity: connectivity,
        syncEngine: syncEngine,
        syncMetaDao: syncMetaDao,
        pullCoordinator: pull,
      );
      await pumpEventQueue();
      statusController.add(true);
      await pumpEventQueue();

      expect(cubit.state.lastSyncAtMs, 5000);
      verify(
        () => syncMetaDao.setCursor(
          '__global_last_sync__',
          cursor: null,
          syncedAt: 5000,
        ),
      ).called(1);
      await cubit.close();
    });

    test(
      'un pull notModified (latestServerTimeMs null) ne régresse pas la date connue',
      () async {
        when(
          () => syncMetaDao.getSyncedAt('__global_last_sync__'),
        ).thenAnswer((_) async => 5000);
        final pull = MockPullCoordinator();
        when(
          () => pull.pullAll(),
        ).thenAnswer((_) async => const PullRunReport(notModified: 1));
        final cubit = SyncStatusCubit(
          outbox: outbox,
          connectivity: connectivity,
          syncEngine: syncEngine,
          syncMetaDao: syncMetaDao,
          pullCoordinator: pull,
        );
        await pumpEventQueue();
        statusController.add(true);
        await pumpEventQueue();

        expect(cubit.state.lastSyncAtMs, 5000);
        await cubit.close();
      },
    );

    test(
      'un simple changement de statut ne régresse pas lastSyncAtMs connu',
      () async {
        when(
          () => syncMetaDao.getSyncedAt('__global_last_sync__'),
        ).thenAnswer((_) async => 5000);
        final cubit = build();
        await pumpEventQueue();
        expect(cubit.state.lastSyncAtMs, 5000);

        statusController.add(false); // offline
        await pumpEventQueue();

        expect(cubit.state.status, SyncStatus.offline);
        expect(cubit.state.lastSyncAtMs, 5000);
        await cubit.close();
      },
    );
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
      syncMetaDao: syncMetaDao,
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

        expect(cubit.state.status, SyncStatus.authRequired);
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

        expect(cubit.state.status, SyncStatus.authRequired);
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
        expect(cubit.state.status, SyncStatus.synced);
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

    test(
      'authRequired PRIME sur syncConflict (l\'auth est la cause racine)',
      () async {
        when(() => probe.canAuthenticate()).thenAnswer((_) async => false);
        when(() => outbox.pendingCount()).thenAnswer((_) async => 3);
        when(() => outbox.errorCount()).thenAnswer((_) async => 1);

        final cubit = buildGated();
        await pumpEventQueue();
        expect(cubit.state.status, SyncStatus.authRequired);
        await cubit.close();
      },
    );

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

  group('ré-authentification silencieuse au retour réseau', () {
    late MockCredentialsProbe probe;
    late MockReauthenticator reauth;
    late MockPullCoordinator pull;

    setUp(() {
      probe = MockCredentialsProbe();
      reauth = MockReauthenticator();
      pull = MockPullCoordinator();
      when(() => probe.canAuthenticate()).thenAnswer((_) async => true);
      when(() => pull.pullAll()).thenAnswer((_) async => const PullRunReport());
    });

    SyncStatusCubit buildReauth() => SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      syncMetaDao: syncMetaDao,
      pullCoordinator: pull,
      credentialsProbe: probe,
      reauthenticator: reauth,
    );

    test('mint réussi → le cycle flush/pull se déroule', () async {
      when(() => reauth.ensureFreshAccess()).thenAnswer((_) async => true);

      final cubit = buildReauth();
      await pumpEventQueue();
      statusController.add(true); // retour réseau
      await pumpEventQueue();

      // La ré-auth précède le trafic : le flush part avec un jeton frais.
      verifyInOrder([
        () => reauth.ensureFreshAccess(),
        () => syncEngine.flush(),
        () => pull.pullAll(),
      ]);
      await cubit.close();
    });

    test(
      'mint impossible → AUCUN flush ni pull, la session reste ouverte',
      () async {
        when(() => reauth.ensureFreshAccess()).thenAnswer((_) async => false);
        when(() => outbox.pendingCount()).thenAnswer((_) async => 2);

        final cubit = buildReauth();
        await pumpEventQueue();
        statusController.add(true);
        await pumpEventQueue();

        // Régression du bug terrain : sans cette garde, chaque entrée partait
        // avec un jeton mort (attempts++ jusqu'au poison SYNC_ERROR) et le
        // rejet ramené par la première requête éjectait l'agent de son écran.
        verifyNever(() => syncEngine.flush());
        verifyNever(() => pull.pullAll());
        // Les écritures restent en file, à repousser au prochain cycle.
        expect(cubit.state.status, SyncStatus.pendingUpload);
        await cubit.close();
      },
    );

    test('ré-authentificateur défaillant → ne gèle pas la synchro', () async {
      when(() => reauth.ensureFreshAccess()).thenThrow(Exception('keystore'));

      final cubit = buildReauth();
      await pumpEventQueue();
      statusController.add(true);
      await pumpEventQueue();

      verify(() => syncEngine.flush()).called(1);
      await cubit.close();
    });

    test('push opportuniste post-écriture : mint d\'abord', () async {
      when(() => reauth.ensureFreshAccess()).thenAnswer((_) async => true);

      final cubit = buildReauth();
      await pumpEventQueue();
      await cubit.notifyLocalWrite();
      await pumpEventQueue();

      // Chemin emprunté par `main.dart` à la transition `authenticated` — donc
      // celui d'un login offline, typiquement avec un access vide à renouveler.
      verifyInOrder([
        () => reauth.ensureFreshAccess(),
        () => syncEngine.flush(),
      ]);
      await cubit.close();
    });
  });
}

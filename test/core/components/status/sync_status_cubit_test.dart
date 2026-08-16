import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/revocation_evaluator.dart';
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

class MockRevocationEvaluator extends Mock implements RevocationEvaluator {}

class MockSyncMetaDao extends Mock implements SyncMetaDao {}

/// Handler qui bloque sur un [Completer] — patron repris de
/// `test/core/offline/pull_coordinator_test.dart`. Sert ici à tenir un cycle
/// de pull *ouvert* le temps d'observer ce que fait un second déclencheur.
class SlowPullHandler implements PullHandler {
  SlowPullHandler(this.gate);

  final Completer<void> gate;
  int calls = 0;

  @override
  String get resource => 'slow';

  @override
  List<Perm> get requiredPermissions => const [Perm.schoolRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    calls++;
    await gate.future;
    return const PullOutcome.updated();
  }
}

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

  group('lecture incomplète (ADR-015 F1)', () {
    late MockPullCoordinator pull;

    setUp(() {
      pull = MockPullCoordinator();
    });

    SyncStatusCubit buildWithPull() => SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      syncMetaDao: syncMetaDao,
      pullCoordinator: pull,
    );

    test('pull dégradé (une ressource refusée) → partiallySynced', () async {
      when(
        () => pull.pullAll(),
      ).thenAnswer((_) async => const PullRunReport(updated: 2, forbidden: 1));

      final cubit = buildWithPull();
      await pumpEventQueue();
      statusController.add(true); // retour réseau → cycle complet
      await pumpEventQueue();

      expect(cubit.state.status, SyncStatus.partiallySynced);
      expect(cubit.state.hasIncompleteRead, isTrue);
      await cubit.close();
    });

    test('pull sain → synced, aucun drapeau levé', () async {
      when(() => pull.pullAll()).thenAnswer(
        (_) async => const PullRunReport(updated: 3, notModified: 4),
      );

      final cubit = buildWithPull();
      await pumpEventQueue();
      statusController.add(true);
      await pumpEventQueue();

      expect(cubit.state.status, SyncStatus.synced);
      expect(cubit.state.hasIncompleteRead, isFalse);
      await cubit.close();
    });

    test(
      'le drapeau est MÉMORISÉ, pas recalculé : une écriture locale ne l\'éteint pas',
      () async {
        // Test central du lot. `notifyLocalWrite` ne fait AUCUN pull : s'il
        // recalculait la dégradation au lieu de la mémoriser, le drapeau
        // s'éteindrait à la première écriture de l'utilisateur — quelques
        // secondes après s'être allumé — et « Partiellement à jour » ne
        // survivrait jamais assez longtemps pour être lu.
        when(
          () => pull.pullAll(),
        ).thenAnswer((_) async => const PullRunReport(forbidden: 2));

        final cubit = buildWithPull();
        await pumpEventQueue();
        statusController.add(true);
        await pumpEventQueue();
        expect(cubit.state.status, SyncStatus.partiallySynced);

        await cubit.notifyLocalWrite();
        await pumpEventQueue();

        // Aucun pull n'a eu lieu depuis : rien n'a pu infirmer la dégradation.
        verify(() => pull.pullAll()).called(1);
        expect(cubit.state.status, SyncStatus.partiallySynced);
        expect(cubit.state.hasIncompleteRead, isTrue);
        await cubit.close();
      },
    );

    test(
      'un rapport skipped puis offline n\'ÉCRASENT PAS un drapeau déjà levé',
      () async {
        // Un cycle déjà en vol (`skipped`) ou sans radio (`offline`) n'a rien
        // observé : le prendre pour « sain » effacerait une dégradation bien
        // réelle, et la pastille repasserait « À jour » sans qu'aucune lecture
        // n'ait rien ramené de plus.
        final reports = <PullRunReport>[
          const PullRunReport(failed: 1),
          const PullRunReport.skipped(),
          const PullRunReport.offline(),
        ];
        var call = 0;
        when(() => pull.pullAll()).thenAnswer((_) async {
          final report = reports[call.clamp(0, reports.length - 1)];
          call++;
          return report;
        });

        final cubit = buildWithPull();
        await pumpEventQueue();

        statusController.add(true); // cycle 1 : dégradé
        await pumpEventQueue();
        expect(cubit.state.hasIncompleteRead, isTrue);

        statusController.add(true); // cycle 2 : skipped
        await pumpEventQueue();
        expect(cubit.state.status, SyncStatus.partiallySynced);
        expect(cubit.state.hasIncompleteRead, isTrue);

        statusController.add(true); // cycle 3 : offline
        await pumpEventQueue();
        expect(cubit.state.status, SyncStatus.partiallySynced);
        expect(cubit.state.hasIncompleteRead, isTrue);

        await cubit.close();
      },
    );

    test('un pull sain postérieur ÉTEINT le drapeau', () async {
      // Symétrique du test précédent : seul un cycle qui a réellement observé
      // quelque chose écrit le drapeau — dans les deux sens. Sans cette
      // extinction, `partiallySynced` serait un état absorbant dont une
      // reprise de droits ne sortirait jamais.
      final reports = <PullRunReport>[
        const PullRunReport(forbidden: 1),
        const PullRunReport(updated: 5),
      ];
      var call = 0;
      when(() => pull.pullAll()).thenAnswer((_) async {
        final report = reports[call.clamp(0, reports.length - 1)];
        call++;
        return report;
      });

      final cubit = buildWithPull();
      await pumpEventQueue();

      statusController.add(true);
      await pumpEventQueue();
      expect(cubit.state.status, SyncStatus.partiallySynced);

      statusController.add(true);
      await pumpEventQueue();
      expect(cubit.state.status, SyncStatus.synced);
      expect(cubit.state.hasIncompleteRead, isFalse);

      await cubit.close();
    });

    test(
      'sans coordinateur injecté : jamais dégradé, jamais d\'exception',
      () async {
        // `pullCoordinator` est optionnel (tests, plateformes partielles) :
        // l'absence de rapport ne doit ni lever ni inventer une dégradation.
        final cubit = build();
        await pumpEventQueue();
        statusController.add(true);
        await pumpEventQueue();

        expect(cubit.state.status, SyncStatus.synced);
        expect(cubit.state.hasIncompleteRead, isFalse);
        await cubit.close();
      },
    );

    test(
      '« À envoyer » PRIME sur « partiellement à jour », le drapeau reste porté',
      () async {
        // Le travail en attente est actionnable, la lecture incomplète ne
        // l'est pas : le statut affiche le premier. Mais le drapeau reste dans
        // l'état — c'est exactement pourquoi il est porté à part du statut :
        // la feuille doit rester atteignable et expliquer les deux.
        when(() => outbox.pendingCount()).thenAnswer((_) async => 2);
        when(
          () => pull.pullAll(),
        ).thenAnswer((_) async => const PullRunReport(forbidden: 1));

        final cubit = buildWithPull();
        await pumpEventQueue();
        statusController.add(true);
        await pumpEventQueue();

        expect(cubit.state.status, SyncStatus.pendingUpload);
        expect(cubit.state.hasIncompleteRead, isTrue);
        await cubit.close();
      },
    );

    // La cause décide s'il existe un geste à offrir. Confondre les deux, c'est
    // soit promettre une reprise qui ne lève rien (droit manquant), soit
    // verrouiller un simple timeout jusqu'au redémarrage de l'application.
    test('échec de transport (failed) → dégradé ET rattrapable', () async {
      when(
        () => pull.pullAll(),
      ).thenAnswer((_) async => const PullRunReport(updated: 2, failed: 1));

      final cubit = buildWithPull();
      await pumpEventQueue();
      statusController.add(true);
      await pumpEventQueue();

      expect(cubit.state.status, SyncStatus.partiallySynced);
      expect(cubit.state.hasIncompleteRead, isTrue);
      // Un nouvel essai peut aboutir : le bandeau a le droit d'offrir le geste.
      expect(cubit.state.hasRetriableRead, isTrue);
      await cubit.close();
    });

    test(
      'droit manquant seul (forbidden) → dégradé mais JAMAIS rattrapable',
      () async {
        // LE test du correctif. Une ressource refusée est sautée à l'identique
        // à chaque cycle : offrir « Réessayer » serait exactement le mensonge
        // que ce lot corrige ailleurs — un geste qui promet de lever une
        // condition qu'il ne touche pas.
        when(() => pull.pullAll()).thenAnswer(
          (_) async => const PullRunReport(updated: 2, forbidden: 1),
        );

        final cubit = buildWithPull();
        await pumpEventQueue();
        statusController.add(true);
        await pumpEventQueue();

        expect(cubit.state.status, SyncStatus.partiallySynced);
        expect(cubit.state.hasIncompleteRead, isTrue);
        expect(cubit.state.hasRetriableRead, isFalse);
        await cubit.close();
      },
    );

    test(
      'syncNow() déclenche un cycle complet — le chemin de reprise',
      () async {
        // Ni ouverture de session, ni retour de radio : les deux seuls autres
        // déclencheurs, dont une tablette posée sur le Wi-Fi de l'école ne voit
        // aucun de la journée. Sans ce point d'entrée public, un échec de
        // transport resterait verrouillé jusqu'au redémarrage.
        when(
          () => pull.pullAll(),
        ).thenAnswer((_) async => const PullRunReport(updated: 1));

        final cubit = buildWithPull();
        await pumpEventQueue();

        await cubit.syncNow();
        await pumpEventQueue();

        verify(() => syncEngine.flush()).called(1);
        verify(() => pull.pullAll()).called(1);
        await cubit.close();
      },
    );

    test(
      'après un cycle sain relancé par syncNow(), les DEUX drapeaux retombent',
      () async {
        // La reprise doit pouvoir éteindre la pastille, sinon elle ne sert à
        // rien : un bandeau qui reste affiché après un rattrapage réussi
        // apprend à l'utilisateur à ne plus le lire.
        final reports = <PullRunReport>[
          const PullRunReport(updated: 1, failed: 2),
          const PullRunReport(updated: 4),
        ];
        var call = 0;
        when(() => pull.pullAll()).thenAnswer((_) async {
          final report = reports[call.clamp(0, reports.length - 1)];
          call++;
          return report;
        });

        final cubit = buildWithPull();
        await pumpEventQueue();
        statusController.add(true); // cycle 1 : transport coupé
        await pumpEventQueue();
        expect(cubit.state.status, SyncStatus.partiallySynced);
        expect(cubit.state.hasIncompleteRead, isTrue);
        expect(cubit.state.hasRetriableRead, isTrue);

        await cubit.syncNow(); // cycle 2 : reprise à la demande
        await pumpEventQueue();

        expect(cubit.state.status, SyncStatus.synced);
        expect(cubit.state.hasIncompleteRead, isFalse);
        expect(cubit.state.hasRetriableRead, isFalse);
        await cubit.close();
      },
    );

    test(
      'syncOnLogin n\'est plus qu\'un alias : même cycle, même état que syncNow',
      () async {
        // Les deux entrées doivent rester indiscernables — sinon l'une des deux
        // dérive, et la reprise cesse de valoir l'ouverture de session.
        when(
          () => pull.pullAll(),
        ).thenAnswer((_) async => const PullRunReport(updated: 1, failed: 1));

        final viaLogin = buildWithPull();
        await pumpEventQueue();
        await viaLogin.syncOnLogin();
        await pumpEventQueue();
        final stateViaLogin = viaLogin.state;
        await viaLogin.close();

        final viaNow = buildWithPull();
        await pumpEventQueue();
        await viaNow.syncNow();
        await pumpEventQueue();

        expect(viaNow.state, stateViaLogin);
        expect(viaNow.state.hasRetriableRead, isTrue);
        await viaNow.close();
      },
    );

    test('syncNow() hors ligne ne tente rien', () async {
      // La pré-garde de connectivité est partagée par les deux entrées : la
      // reprise à la demande ne doit pas devenir le trou par lequel une session
      // sans radio part quand même en 401.
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);
      when(() => pull.pullAll()).thenAnswer((_) async => const PullRunReport());

      final cubit = buildWithPull();
      await pumpEventQueue();

      await cubit.syncNow();
      await pumpEventQueue();

      verifyNever(() => syncEngine.flush());
      verifyNever(() => pull.pullAll());
      expect(cubit.state.status, SyncStatus.offline);
      await cubit.close();
    });
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

      // Chemin du *write-path* : emprunté par les repositories après chaque
      // écriture locale réussie. (`main.dart` ne passe plus par là à la
      // transition `authenticated` — il appelle désormais `syncOnLogin`.) Le
      // mint reste exigé en tête : une écriture peut suivre de peu un login
      // offline, donc porter un access vide à renouveler.
      verifyInOrder([
        () => reauth.ensureFreshAccess(),
        () => syncEngine.flush(),
      ]);
      await cubit.close();
    });
  });

  // ADR-015 F0 — jusqu'ici le cycle de coordinateur n'avait qu'UN déclencheur,
  // la transition hors-ligne → en ligne. Une tablette allumée le matin dans une
  // école déjà couverte en Wi-Fi n'en exécutait donc aucun de la journée : son
  // cache n'était hydraté que par les pulls lancés écran par écran.
  group('syncOnLogin — cycle à l\'ouverture de session', () {
    late MockCredentialsProbe probe;
    late MockReauthenticator reauth;
    late MockRevocationEvaluator revocation;
    late MockPullCoordinator pull;

    setUp(() {
      probe = MockCredentialsProbe();
      reauth = MockReauthenticator();
      revocation = MockRevocationEvaluator();
      pull = MockPullCoordinator();
      when(() => probe.canAuthenticate()).thenAnswer((_) async => true);
      when(() => reauth.ensureFreshAccess()).thenAnswer((_) async => true);
      when(
        () => revocation.evaluateRevocation(),
      ).thenAnswer((_) async => false);
      when(() => pull.pullAll()).thenAnswer((_) async => const PullRunReport());
    });

    SyncStatusCubit buildLogin() => SyncStatusCubit(
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: syncEngine,
      syncMetaDao: syncMetaDao,
      pullCoordinator: pull,
      revocationEvaluator: revocation,
      credentialsProbe: probe,
      reauthenticator: reauth,
    );

    test('un cycle à l\'authentification : le pull a bien lieu', () async {
      final cubit = buildLogin();
      await pumpEventQueue();

      await cubit.syncOnLogin();
      await pumpEventQueue();

      verify(() => pull.pullAll()).called(1);
      expect(cubit.state.status, SyncStatus.synced);
      await cubit.close();
    });

    test('ordre du cycle : mint → flush → pull', () async {
      final cubit = buildLogin();
      await pumpEventQueue();

      await cubit.syncOnLogin();
      await pumpEventQueue();

      // Même séquence que le retour réseau (ADR-010 D-11) : le jeton est
      // rafraîchi AVANT tout appel authentifié, l'outbox est drainée avant
      // qu'on ne tire — le travail saisi hors ligne part en premier.
      verifyInOrder([
        () => reauth.ensureFreshAccess(),
        () => syncEngine.flush(),
        () => pull.pullAll(),
      ]);
      await cubit.close();
    });

    test('aucun cycle si la session est ouverte hors ligne', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

      final cubit = buildLogin();
      await pumpEventQueue();

      await cubit.syncOnLogin();
      await pumpEventQueue();

      verifyNever(() => pull.pullAll());
      verifyNever(() => syncEngine.flush());
      expect(cubit.state.status, SyncStatus.offline);
      await cubit.close();
    });

    test('session sans jetons : aucun flush, aucun pull', () async {
      // Session rouverte hors connexion puis réseau revenu, mais consigne
      // brûlée : flusher ne ferait que consommer une tentative par entrée en
      // 401, jusqu'au poison SYNC_ERROR.
      when(() => probe.canAuthenticate()).thenAnswer((_) async => false);
      when(() => outbox.pendingCount()).thenAnswer((_) async => 2);

      final cubit = buildLogin();
      await pumpEventQueue();

      await cubit.syncOnLogin();
      await pumpEventQueue();

      verifyNever(() => syncEngine.flush());
      verifyNever(() => pull.pullAll());
      expect(cubit.state.status, SyncStatus.authRequired);
      await cubit.close();
    });

    test('mint impossible : aucun flush, aucun pull', () async {
      // LE cas du login offline « radio allumée, serveur injoignable » : la
      // pré-garde de connectivité de `syncOnLogin` ne lit que l'état RADIO et
      // laisse donc passer. Seule cette garde-ci arrête le cycle — sans elle,
      // chaque entrée de la file partirait avec un access mort.
      when(() => reauth.ensureFreshAccess()).thenAnswer((_) async => false);
      when(() => outbox.pendingCount()).thenAnswer((_) async => 2);

      final cubit = buildLogin();
      await pumpEventQueue();

      await cubit.syncOnLogin();
      await pumpEventQueue();

      verifyNever(() => syncEngine.flush());
      verifyNever(() => pull.pullAll());
      // La session reste ouverte, la file intacte : le prochain cycle retentera.
      expect(cubit.state.status, SyncStatus.pendingUpload);
      await cubit.close();
    });

    test('révocation détectée : le flush a lieu, le pull non', () async {
      // Ordre `flush → evaluate → pull` (ADR-010 D-11) : le travail légitime
      // saisi hors ligne est drainé AVANT qu'on ne constate la révocation —
      // wiper la session ne détruit jamais l'outbox. Mais on ne tire plus rien
      // dans un cache dont la session vient d'être invalidée.
      when(() => revocation.evaluateRevocation()).thenAnswer((_) async => true);

      final cubit = buildLogin();
      await pumpEventQueue();

      await cubit.syncOnLogin();
      await pumpEventQueue();

      verify(() => syncEngine.flush()).called(1);
      verifyNever(() => pull.pullAll());
      await cubit.close();
    });

    test('l\'heure serveur du rapport avance et persiste la date', () async {
      when(() => pull.pullAll()).thenAnswer(
        (_) async => const PullRunReport(updated: 2, latestServerTimeMs: 9000),
      );

      final cubit = buildLogin();
      await pumpEventQueue();

      await cubit.syncOnLogin();
      await pumpEventQueue();

      expect(cubit.state.lastSyncAtMs, 9000);
      verify(
        () => syncMetaDao.setCursor(
          '__global_last_sync__',
          cursor: null,
          syncedAt: 9000,
        ),
      ).called(1);
      await cubit.close();
    });

    test(
      'pas de second cycle si la connectivité oscille au démarrage',
      () async {
        // Deux déclencheurs coexistent désormais (login + retour réseau) et
        // peuvent se chevaucher à la seconde près au démarrage. Ce qui protège,
        // c'est le verrou `_pulling` du coordinateur — d'où un VRAI
        // `PullCoordinator` ici, un mock ne dirait rien de cette garantie.
        final gate = Completer<void>();
        final slow = SlowPullHandler(gate);
        final coordinator = PullCoordinator(connectivity: connectivity)
          ..registerHandler(slow);
        final cubit = SyncStatusCubit(
          outbox: outbox,
          connectivity: connectivity,
          syncEngine: syncEngine,
          syncMetaDao: syncMetaDao,
          pullCoordinator: coordinator,
          revocationEvaluator: revocation,
          credentialsProbe: probe,
          reauthenticator: reauth,
        );
        await pumpEventQueue();

        // Le cycle de login part et reste bloqué DANS le pull.
        unawaited(cubit.syncOnLogin());
        await pumpEventQueue();
        expect(coordinator.isPulling, isTrue);

        // La radio bascule à online dans la foulée : second déclencheur.
        statusController.add(true);
        await pumpEventQueue();

        // Le second cycle a bel et bien tourné jusqu'au pull (il a poussé) :
        // la garantie vérifiée juste après n'est pas vacante.
        verify(() => syncEngine.flush()).called(2);
        // Il est rendu `skipped` : une seule descente de données, pas deux
        // passes concurrentes sur la même ressource.
        expect(slow.calls, 1);

        gate.complete();
        await pumpEventQueue();
        expect(coordinator.isPulling, isFalse);
        await cubit.close();
      },
    );
  });
}

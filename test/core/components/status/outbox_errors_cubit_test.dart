import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
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

  group('écritures en attente d\'un autre compte', () {
    OutboxEntry authored(String id, String? authorId, {int createdAt = 1000}) =>
        OutboxEntry(
          id: id,
          aggregateType: 'PAYMENT',
          aggregateId: 'agg-$id',
          operation: OutboxOperation.create,
          payload: jsonEncode({'authorId': ?authorId}),
          createdAt: createdAt,
        );

    OutboxErrorsCubit build({
      String? me = 'uid-moi',
      OutboxAuthorDirectory? directory,
    }) => OutboxErrorsCubit(
      outbox: dao,
      syncEngine: engine,
      currentUser: CurrentUserContext()..set(me),
      authorDirectory: directory,
    );

    test('agrège le nombre, la plus ancienne et le nom du collègue', () async {
      await dao.enqueue(authored('a1', 'uid-autre', createdAt: 5000));
      await dao.enqueue(authored('a2', 'uid-autre', createdAt: 2000));
      await dao.enqueue(authored('mine', 'uid-moi', createdAt: 1000));

      final cubit = build(
        directory: _Directory({
          'uid-autre': const OutboxAuthorIdentity(
            firstName: 'Marie',
            lastName: 'Kabila',
          ),
        }),
      );
      await cubit.load();

      expect(cubit.state.others.count, 2);
      expect(cubit.state.others.oldestCreatedAt, 2000);
      expect(cubit.state.otherAuthors.single?.firstName, 'Marie');
    });

    test('compte les entrées REPORTÉES par la garde : elles ont un '
        'next_attempt_at futur, donc pendingReady ne les voit pas', () async {
      await dao.enqueue(authored('a1', 'uid-autre'));
      await dao.defer('a1', nextAttemptAt: 99999999999, reason: 'autre compte');

      final cubit = build();
      await cubit.load();

      expect(
        cubit.state.others.count,
        1,
        reason: 'pendingAll, pas pendingReady',
      );
    });

    test(
      'un annuaire qui lève dégrade en anonyme, sans perdre l\'information',
      () async {
        await dao.enqueue(authored('a1', 'uid-autre'));

        final cubit = build(directory: _ThrowingDirectory());
        await cubit.load();

        expect(cubit.state.others.count, 1);
        expect(cubit.state.otherAuthors, [null]);
      },
    );

    test('les entrées sans auteur ne sont jamais comptées comme celles d\'un '
        'autre compte', () async {
      await dao.enqueue(authored('a1', null));

      final cubit = build();
      await cubit.load();

      expect(cubit.state.others.isEmpty, isTrue);
    });

    test('porteur inconnu : aucun agrégat, pas de bande trompeuse', () async {
      await dao.enqueue(authored('a1', 'uid-autre'));

      final cubit = build(me: null);
      await cubit.load();

      expect(cubit.state.others.isEmpty, isTrue);
    });

    test('l\'agrégat ne fait JAMAIS basculer la feuille en échec : les erreurs '
        'de l\'utilisateur restent la raison d\'être de l\'écran', () async {
      await dao.enqueue(authored('ko', 'uid-moi'));
      await dao.markSyncError('ko', 'rejet serveur');
      await dao.enqueue(authored('a1', 'uid-autre'));

      final cubit = build(directory: _ThrowingDirectory());
      await cubit.load();

      expect(cubit.state.status, OutboxErrorsStatus.loaded);
      expect(cubit.state.entries.single.id, 'ko');
    });
  });

  group('rejeu impossible et retenue visible', () {
    OutboxEntry authored(
      String id,
      String? authorId, {
      String type = 'PAYMENT',
    }) => OutboxEntry(
      id: id,
      aggregateType: type,
      aggregateId: 'agg-$id',
      operation: OutboxOperation.create,
      payload: jsonEncode({'authorId': ?authorId}),
      createdAt: 1000,
    );

    OutboxErrorsCubit build({String? me = 'uid-moi'}) => OutboxErrorsCubit(
      outbox: dao,
      syncEngine: engine,
      currentUser: CurrentUserContext()..set(me),
    );

    test(
      'retry sur une entrée d\'un AUTRE compte est refusé : la rejouer la '
      'ferait quitter SYNC_ERROR et disparaître de la liste sans partir',
      () async {
        await dao.enqueue(authored('a1', 'uid-autre'));
        await dao.markSyncError('a1', 'rejet');

        final cubit = build();
        await cubit.load();
        await cubit.retry('a1');

        final row = (await db.query(
          'outbox',
          where: 'id = ?',
          whereArgs: ['a1'],
        )).single;
        expect(row['status'], 'SYNC_ERROR', reason: 'toujours visible');
      },
    );

    test('retry sur MON entrée fonctionne toujours', () async {
      await dao.enqueue(authored('m1', 'uid-moi'));
      await dao.markSyncError('m1', 'rejet');

      final cubit = build();
      await cubit.load();
      await cubit.retry('m1');

      final row = (await db.query(
        'outbox',
        where: 'id = ?',
        whereArgs: ['m1'],
      )).single;
      expect(row['status'], 'PENDING');
    });

    test('retryAll saute les entrées d\'un autre compte', () async {
      await dao.enqueue(authored('a1', 'uid-autre'));
      await dao.markSyncError('a1', 'rejet');
      await dao.enqueue(authored('m1', 'uid-moi'));
      await dao.markSyncError('m1', 'rejet');

      final cubit = build();
      await cubit.load();
      await cubit.retryAll();

      Future<Object?> statusOf(String id) async => (await db.query(
        'outbox',
        where: 'id = ?',
        whereArgs: [id],
      )).single['status'];
      expect(await statusOf('a1'), 'SYNC_ERROR');
      expect(await statusOf('m1'), 'PENDING');
    });

    test('mes écritures RETENUES sont exposées avec leur motif — sans ça un '
        'paiement bloqué n\'existe nulle part à l\'écran', () async {
      await dao.enqueue(authored('m1', 'uid-moi'));
      await dao.defer(
        'm1',
        nextAttemptAt: 99999999999,
        reason: 'Inscription de l\'élève non synchronisée (dépendance)',
      );

      final cubit = build();
      await cubit.load();

      expect(cubit.state.held.single.id, 'm1');
      expect(cubit.state.held.single.lastError, contains('Inscription'));
      expect(cubit.state.isEmpty, isFalse, reason: 'pas d\'écran vide menteur');
    });

    test('les entrées retenues d\'un AUTRE compte ne polluent pas ma section '
        '« En attente » : elles ont leur propre bande', () async {
      await dao.enqueue(authored('a1', 'uid-autre'));
      await dao.defer('a1', nextAttemptAt: 99999999999, reason: 'autre compte');

      final cubit = build();
      await cubit.load();

      expect(cubit.state.held, isEmpty);
      expect(cubit.state.others.count, 1);
    });

    test('une entrée en attente JAMAIS tentée (aucun motif) n\'est pas '
        'présentée comme retenue', () async {
      await dao.enqueue(authored('m1', 'uid-moi'));

      final cubit = build();
      await cubit.load();

      expect(cubit.state.held, isEmpty);
      expect(cubit.state.isEmpty, isTrue);
    });
  });

  // B-5 — la feuille était chargée une fois et ne bougeait plus. Le battement
  // de la file a périmé cette hypothèse : un flush automatique peut acquitter
  // et supprimer, pendant la lecture, une ligne que la feuille liste encore.
  // Le tap « Réessayer » devient alors un no-op MUET — `requeue` ne touche que
  // les `SYNC_ERROR`, et il n'y a plus de ligne à toucher.
  group('la liste suit les flush du moteur', () {
    test('un flush qui acquitte une entrée la retire de la feuille', () async {
      engine.registerHandler(
        _ScriptedHandler('PAYMENT', const OutboxDispatchResult.acked()),
      );
      await dao.enqueue(entry(id: 'p1'));
      await dao.markSyncError('p1', 'rejet initial');

      final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
      await cubit.load();
      expect(cubit.state.entries, hasLength(1));

      // La notification de fin de flush est synchrone ; la RELECTURE qu'elle
      // déclenche ne l'est pas : `_onFlushCompleted` lance `load()` sans
      // l'attendre, et `load()` interroge la base avant d'émettre. Céder un
      // seul tour de boucle — `Future.delayed(Duration.zero)` — pariait donc
      // sur le nombre de micro-tâches d'une lecture SQL. Le pari passait sur
      // une machine au repos et tombait sur un runner chargé : c'est ce qui
      // rendait ce test intermittent. On attend l'ÉMISSION, pas un délai.
      //
      // ⚠️ L'abonnement est pris AVANT le flush. Après, l'émission pourrait
      // déjà avoir eu lieu, et `firstWhere` attendrait un événement passé —
      // le test se figerait au lieu de rougir.
      final feuilleVidee = cubit.stream.firstWhere((s) => s.entries.isEmpty);

      // Le battement remet la ligne en file et la pousse : c'est le flush du
      // MOTEUR, pas celui de la feuille.
      await dao.requeue('p1');
      await engine.flush();
      await feuilleVidee.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw StateError(
          'la feuille n\'a pas été relue après le flush du moteur',
        ),
      );

      expect(
        cubit.state.entries,
        isEmpty,
        reason: 'la feuille ne doit pas survivre à ce qu\'elle liste',
      );
      await cubit.close();
    });

    test('fermée, la feuille ne s\'abonne plus à rien', () async {
      final cubit = OutboxErrorsCubit(outbox: dao, syncEngine: engine);
      await cubit.load();
      await cubit.close();

      // Ne doit ni lever ni émettre sur un cubit fermé.
      await engine.flush();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isClosed, isTrue);
    });
  });
}

/// Annuaire de test.
class _Directory implements OutboxAuthorDirectory {
  final Map<String, OutboxAuthorIdentity> _byUid;
  _Directory(this._byUid);

  @override
  Future<OutboxAuthorIdentity?> identityOf(String uid) async => _byUid[uid];
}

class _ThrowingDirectory implements OutboxAuthorDirectory {
  @override
  Future<OutboxAuthorIdentity?> identityOf(String uid) async =>
      throw StateError('annuaire indisponible');
}

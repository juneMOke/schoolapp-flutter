import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_holder.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_repository.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';

/// Un faux repository **à compteurs**, et non un mock : ce qui est vérifié ici
/// n'est pas « telle méthode a été appelée » mais « combien de fois », et il
/// faut en plus pouvoir tenir une lecture ouverte pour éprouver le verrou de
/// simultanéité. Un `Completer` piloté depuis le test dit cela ; une pile de
/// `when(...)` non.
class _FauxSyncPlanRepository implements SyncPlanRepository {
  int appelsRefresh = 0;
  int appelsLoadCached = 0;
  int appelsLoad = 0;

  /// Ce que rend la jambe réseau. `null` = elle n'a **pas** abouti — c'est la
  /// distinction que [SyncPlanRepository.refreshFromNetwork] existe à porter.
  SyncPlanState? reseau;

  /// Ce que rend le cache local.
  SyncPlanState cache = const SyncPlanState.unknown(
    SyncPlanUnknownCause.absent,
  );

  /// Posée, elle suspend `refreshFromNetwork` : c'est ainsi qu'une première
  /// lecture reste ouverte pendant que d'autres appels arrivent.
  Completer<void>? porte;

  /// Le contrat dit que le repository ne lève jamais. Ce drapeau permet de
  /// vérifier que le porteur tient quand même si le contrat est trahi.
  bool leve = false;

  @override
  Future<SyncPlanState?> refreshFromNetwork() async {
    appelsRefresh++;
    final porte = this.porte;
    if (porte != null) await porte.future;
    if (leve) throw StateError('le repository a levé');
    return reseau;
  }

  @override
  Future<SyncPlanState> loadCached() async {
    appelsLoadCached++;
    if (leve) throw StateError('le repository a levé');
    return cache;
  }

  @override
  Future<SyncPlanState> load() async {
    appelsLoad++;
    return cache;
  }
}

/// Un plan minimal. Le porteur ne lit rien de son contenu — il le mémorise et
/// le rend — mais le fabriquer fidèlement (clés réelles, ressources dérivées de
/// [resourcesOf]) évite qu'un test passe sur un plan que le serveur n'enverrait
/// jamais.
SyncPlan _plan(List<String> cles, {String subject = 'uid-serveur-A'}) =>
    SyncPlan(
      planVersion: 1,
      subject: subject,
      onAbsence: 'ignore',
      streams: [
        for (final cle in cles)
          SyncPlanFlow(
            key: cle,
            clientResource: resourcesOf(cle),
            mode: SyncFlowMode.keyset,
            scope: SyncFlowScope.school,
            reason: const ['socle'],
            dependsOn: const [],
          ),
      ],
    );

void main() {
  late _FauxSyncPlanRepository repo;

  setUp(() => repo = _FauxSyncPlanRepository());

  SyncPlanHolder porteur({CurrentPermissions? permissions}) {
    final holder = SyncPlanHolder(repository: repo, permissions: permissions);
    addTearDown(holder.dispose);
    return holder;
  }

  group('mémo — le plan est résolu une fois, pas à chaque cycle', () {
    test(
      'le premier current() lit, le second sert le mémo SANS relire',
      () async {
        // `pullSubset` part au montage de sept écrans ; relire le plan à chaque
        // fois ferait une dizaine de GET pleins par minute, le plan n'ayant
        // délibérément pas d'ETag.
        final connu = SyncPlanState.known(
          _plan(const [SyncPlanKeys.classroomClassrooms]),
        );
        repo.reseau = connu;
        final holder = porteur();

        final premier = await holder.current();
        final second = await holder.current();

        expect(repo.appelsRefresh, 1);
        expect(premier, same(connu));
        expect(second, same(connu));
        expect(holder.memo, same(connu));
        expect(holder.isStale, isFalse);
      },
    );

    test('le mémo est vide et le drapeau levé avant toute lecture', () {
      final holder = porteur();

      expect(holder.memo, isNull);
      expect(holder.isStale, isTrue);
      expect(repo.appelsRefresh, 0, reason: 'la construction ne lit rien');
    });

    test('markStale() force une relecture au prochain current()', () async {
      repo.reseau = SyncPlanState.known(
        _plan(const [SyncPlanKeys.financePayments]),
      );
      final holder = porteur();
      await holder.current();
      expect(repo.appelsRefresh, 1);

      holder.markStale();
      expect(holder.isStale, isTrue);
      expect(holder.memo, isNotNull, reason: 'périmé n\'est pas oublié');

      await holder.current();

      expect(repo.appelsRefresh, 2);
    });
  });

  group('single-flight — un seul appel en vol', () {
    test(
      'trois current() concurrents sur un mémo vide ⇒ UNE seule lecture',
      () async {
        // Le cas réel : un aller-retour d'ouverture de la Facturation lance trois
        // `pullSubset` non attendus.
        final connu = SyncPlanState.known(
          _plan(const [SyncPlanKeys.financeStudentCharges]),
        );
        repo.reseau = connu;
        final porte = Completer<void>();
        repo.porte = porte;
        final holder = porteur();

        final premier = holder.current();
        final second = holder.current();
        final troisieme = holder.current();

        expect(
          repo.appelsRefresh,
          1,
          reason: 'les deux appels tardifs rejoignent le futur en vol',
        );

        porte.complete();
        final resultats = await Future.wait([premier, second, troisieme]);

        expect(repo.appelsRefresh, 1);
        expect(resultats[0], same(connu));
        expect(resultats[1], same(connu));
        expect(resultats[2], same(connu));
      },
    );

    test(
      'le verrou est relâché : une lecture ultérieure repart bien',
      () async {
        repo.reseau = const SyncPlanState.unknown(
          SyncPlanUnknownCause.notDeployed,
        );
        final porte = Completer<void>();
        repo.porte = porte;
        final holder = porteur();

        final premier = holder.current();
        porte.complete();
        await premier;
        repo.porte = null;

        holder.markStale();
        await holder.current();

        expect(repo.appelsRefresh, 2);
      },
    );
  });

  group('péremption — un plan périmé se sait périmé (F9)', () {
    test(
      'la relecture en ÉCHEC sert le cache mais laisse le drapeau levé',
      () async {
        // Sous F5, un plan périmé RESTREINT le pull : il ne se contente pas
        // d'être en retard. Croire à jour un plan replié sur le cache figerait le
        // périmètre de synchronisation jusqu'au prochain login.
        final enCache = SyncPlanState.known(
          _plan(const [SyncPlanKeys.classroomClassrooms]),
        );
        repo.reseau = null;
        repo.cache = enCache;
        final holder = porteur();

        final etat = await holder.current();

        expect(
          etat,
          same(enCache),
          reason: 'ce que la tablette a vaut mieux que rien',
        );
        expect(repo.appelsLoadCached, 1);
        expect(holder.isStale, isTrue, reason: 'le drapeau RESTE levé');
      },
    );

    test('et le cycle suivant relit vraiment', () async {
      repo.reseau = null;
      repo.cache = SyncPlanState.known(
        _plan(const [SyncPlanKeys.classroomClassrooms]),
      );
      final holder = porteur();
      await holder.current();

      await holder.current();

      expect(repo.appelsRefresh, 2);
      expect(repo.appelsLoadCached, 2);
    });

    test('un verdict serveur OBTENU fait retomber le drapeau, même '
        'Unknown(notDeployed)', () async {
      // « Route absente » est un verdict, pas un échec : il n'y a rien à
      // retenter, et retenter ajouterait un timeout par montage d'écran sur un
      // parc dont le back n'est pas déployé.
      const verdict = SyncPlanState.unknown(SyncPlanUnknownCause.notDeployed);
      repo.reseau = verdict;
      final holder = porteur();

      final etat = await holder.current();

      expect(etat, same(verdict));
      expect(holder.isStale, isFalse);
      expect(repo.appelsLoadCached, 0, reason: 'le cache n\'est pas sollicité');

      await holder.current();

      expect(repo.appelsRefresh, 1, reason: 'servi depuis le mémo');
    });

    test(
      'un plan VIDE obtenu du réseau est un verdict, pas un manque',
      () async {
        final vide = SyncPlanState.empty(_plan(const []));
        repo.reseau = vide;
        final holder = porteur();

        final etat = await holder.current();

        expect(etat, same(vide));
        expect(holder.isStale, isFalse);
      },
    );
  });

  group('permissions — le signal de relecture (F9)', () {
    test('un changement de permissions marque le plan périmé', () async {
      final permissions = CurrentPermissions()..set(const ['classroom.read']);
      repo.reseau = SyncPlanState.known(
        _plan(const [SyncPlanKeys.classroomClassrooms]),
      );
      final holder = porteur(permissions: permissions);
      await holder.current();
      expect(holder.isStale, isFalse);

      permissions.set(const ['classroom.read', 'finance.payment.read']);

      expect(holder.isStale, isTrue);
      expect(holder.memo, isNotNull, reason: 'périmé, pas oublié');

      await holder.current();

      expect(repo.appelsRefresh, 2);
    });

    test('un ensemble RÉÉMIS à l\'identique ne marque rien', () async {
      // Sans quoi chaque refresh de jeton relirait le plan — et sous F5, un
      // plan perpétuellement « à relire » restreint le pull en permanence.
      final permissions = CurrentPermissions()
        ..set(const ['classroom.read', 'finance.payment.read']);
      repo.reseau = SyncPlanState.known(
        _plan(const [SyncPlanKeys.classroomClassrooms]),
      );
      final holder = porteur(permissions: permissions);
      await holder.current();

      permissions.set(const ['finance.payment.read', 'classroom.read']);

      expect(holder.isStale, isFalse);

      await holder.current();

      expect(repo.appelsRefresh, 1);
    });

    test('un ensemble qui devient NULL (logout) fait OUBLIER, pas seulement '
        'marquer périmé', () async {
      // Garde tablette partagée : le porteur vit aussi longtemps que
      // l'application, le plan appartient à un compte. Sous F5, un plan
      // survivant décide de ce que le compte SUIVANT tire.
      final permissions = CurrentPermissions()..set(const ['classroom.read']);
      repo.reseau = SyncPlanState.known(
        _plan(const [SyncPlanKeys.classroomClassrooms]),
      );
      final holder = porteur(permissions: permissions);
      await holder.current();
      expect(holder.memo, isNotNull);

      permissions.clear();

      expect(
        holder.memo,
        isNull,
        reason: 'rien ne survit à une bascule de compte',
      );
      expect(holder.isStale, isTrue);
    });

    test('clear() direct remet à l\'état initial', () async {
      repo.reseau = SyncPlanState.known(
        _plan(const [SyncPlanKeys.classroomClassrooms]),
      );
      final holder = porteur();
      await holder.current();

      holder.clear();

      expect(holder.memo, isNull);
      expect(holder.isStale, isTrue);

      await holder.current();

      expect(repo.appelsRefresh, 2);
    });

    test(
      'dispose() désabonne : un changement postérieur ne marque plus rien',
      () async {
        final permissions = CurrentPermissions()..set(const ['classroom.read']);
        repo.reseau = SyncPlanState.known(
          _plan(const [SyncPlanKeys.classroomClassrooms]),
        );
        final holder = SyncPlanHolder(
          repository: repo,
          permissions: permissions,
        );
        await holder.current();
        expect(holder.isStale, isFalse);

        holder.dispose();
        permissions.set(const ['finance.payment.read']);

        expect(holder.isStale, isFalse);
        expect(holder.memo, isNotNull);

        permissions.clear();

        expect(
          holder.memo,
          isNotNull,
          reason: 'plus abonné, donc plus d\'oubli',
        );
      },
    );

    test('dispose() est idempotent', () async {
      final permissions = CurrentPermissions();
      final holder = SyncPlanHolder(repository: repo, permissions: permissions);

      holder.dispose();

      expect(holder.dispose, returnsNormally);
    });

    test('sans CurrentPermissions, le porteur fonctionne quand même', () async {
      final connu = SyncPlanState.known(
        _plan(const [SyncPlanKeys.classroomClassrooms]),
      );
      repo.reseau = connu;
      final holder = porteur();

      expect(await holder.current(), same(connu));
    });
  });

  group('robustesse — le porteur ne propage jamais', () {
    test(
      'un repository qui LÈVE rend un plan inconnu, sans exception',
      () async {
        // Le contrat interdit qu'il lève ; une lecture qui remonterait une
        // exception couperait la synchronisation sans recours.
        repo.leve = true;
        final holder = porteur();

        final etat = await holder.current();

        expect(etat, isA<SyncPlanUnknown>());
        expect((etat as SyncPlanUnknown).cause, SyncPlanUnknownCause.absent);
        expect(holder.isStale, isTrue, reason: 'un échec se retente');
      },
    );

    test(
      'un échec ne fige pas le verrou : la lecture suivante repart',
      () async {
        repo.leve = true;
        final holder = porteur();
        await holder.current();

        repo.leve = false;
        final connu = SyncPlanState.known(
          _plan(const [SyncPlanKeys.classroomClassrooms]),
        );
        repo.reseau = connu;

        expect(await holder.current(), same(connu));
        expect(repo.appelsRefresh, 2);
      },
    );
  });

  // ───────────────────────────────────────────────────────────────────────────
  // COURSES TROUVÉES EN REVUE, FERMÉES — et ces deux tests sont leur SEULE
  // couverture : les retirer rouvrirait le défaut en silence.
  //
  // Racine commune : `_resolve()` écrivait `_memo` et `_stale` à son retour sans
  // vérifier que le monde n'avait pas bougé pendant l'aller-retour réseau. Une
  // lecture partie avant un élargissement de droits revenait la marquer fraîche ;
  // une lecture partie avant un logout ressuscitait le plan du compte parti.
  //
  // Fermé par le jeton `_generation` : incrémenté par `markStale()` et
  // `clear()`, capturé au départ de `_resolve()`, comparé par `_commit()` avant
  // toute écriture. `clear()` abandonne en plus la lecture en vol, pour qu'un
  // arrivant ne s'y coalesce pas et ne reçoive pas le plan de quelqu'un d'autre.
  // ───────────────────────────────────────────────────────────────────────────
  group('courses entre une lecture en vol et un changement de session', () {
    test('un logout PENDANT une lecture ne doit pas laisser le plan de A être '
        'réécrit après le wipe', () async {
      // C'est exactement la garantie que la classe annonce : « entre le wipe et
      // la première relecture, une copie survivante gouvernerait le pull du
      // compte suivant ». Sous F5 ce n'est plus un affichage, c'est le
      // périmètre de synchronisation de B.
      final permissions = CurrentPermissions()..set(const ['classroom.read']);
      final planDeA = SyncPlanState.known(
        _plan(const [SyncPlanKeys.financePayments], subject: 'uid-serveur-A'),
      );
      repo.reseau = planDeA;
      final porte = Completer<void>();
      repo.porte = porte;
      final holder = porteur(permissions: permissions);

      final enVol = holder.current();
      permissions.clear(); // logout pendant l'aller-retour
      expect(holder.memo, isNull, reason: 'le wipe a bien eu lieu');

      porte.complete();
      await enVol;

      expect(
        holder.memo,
        isNull,
        reason:
            'la réponse arrivée APRÈS le wipe ne doit pas réinstaller le '
            'plan du compte A',
      );
    });

    test('un changement de permissions PENDANT une lecture doit laisser le '
        'drapeau levé', () async {
      // La réponse en vol a été calculée par le serveur AVANT le nouvel
      // ensemble : la déclarer fraîche fait perdre le signal, et le droit
      // élargi reste sans effet jusqu'au prochain changement — la régression
      // même que F9 existe à empêcher.
      final permissions = CurrentPermissions()..set(const ['classroom.read']);
      repo.reseau = SyncPlanState.known(
        _plan(const [SyncPlanKeys.classroomClassrooms]),
      );
      final porte = Completer<void>();
      repo.porte = porte;
      final holder = porteur(permissions: permissions);

      final enVol = holder.current();
      permissions.set(const ['classroom.read', 'finance.payment.read']);
      expect(holder.isStale, isTrue);

      porte.complete();
      await enVol;

      expect(
        holder.isStale,
        isTrue,
        reason:
            'le plan reçu précède le changement de droits : il reste à '
            'relire',
      );
    });
  });
}

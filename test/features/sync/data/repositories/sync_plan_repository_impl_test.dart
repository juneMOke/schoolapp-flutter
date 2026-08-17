import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/sync/data/datasources/sync_plan_api.dart';
import 'package:school_app_flutter/features/sync/data/repositories/sync_plan_repository_impl.dart';

import '../../../../core/offline/offline_full_test_db.dart';

class MockSyncPlanApi extends Mock implements SyncPlanApi {}

/// Une erreur qui n'est PAS une `DioException` et qui n'a même pas de champ
/// `response` : ce que peut produire le socle, un intercepteur, ou un bug.
class ErreurQuelconque implements Exception {
  const ErreurQuelconque();
}

/// Base hors service : toute lecture ou écriture lève.
///
/// Préférée à la fermeture de la vraie base sqflite : fermer puis rouvrir
/// l'isolat ffi en cours de suite rendait le test suivant instable
/// (« did not complete » sous charge).
class BaseIndisponible implements DatabaseExecutor {
  const BaseIndisponible();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('base indisponible');
}

void main() {
  late Database db;
  late MockSyncPlanApi api;
  late SyncMetaDao syncMeta;
  late CurrentUserContext currentUser;
  late SyncPlanRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const uidA = 'uid-a';
  const uidB = 'uid-b';
  const cleA = '${SyncPlanRepositoryImpl.kPlanResource}@$uidA';
  const cleB = '${SyncPlanRepositoryImpl.kPlanResource}@$uidB';

  setUp(() async {
    // `noIsolate` : les requêtes sont servies dans l'isolat courant. L'isolat de
    // travail ffi cale sous contention CPU et fait « did not complete » toute la
    // fin du fichier — un flake déjà présent sur `outbox_dao_test.dart`.
    db = await openFullOfflineDb(noIsolate: true);
    api = MockSyncPlanApi();
    syncMeta = SyncMetaDao(db);
    currentUser = CurrentUserContext()..set(uidA);
    repo = SyncPlanRepositoryImpl(
      api: api,
      syncMetaDao: syncMeta,
      currentUser: currentUser,
      requiredAuth: auth,
    );
  });

  tearDown(() async => db.close());

  Map<String, Object?> planBody({
    String subject = uidA,
    int planVersion = 1,
    List<Object?> streams = const <Object?>[
      {
        'key': 'socle',
        'clientResource': ['ref_school'],
        'mode': 'BUNDLE',
        'scope': 'school',
        'reason': ['socle'],
        'dependsOn': <String>[],
      },
    ],
  }) => <String, Object?>{
    'planVersion': planVersion,
    'subject': subject,
    'onAbsence': 'ignore',
    'streams': streams,
  };

  HttpResponse<dynamic> httpOk(Object? body) => HttpResponse<dynamic>(
    body,
    Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
  );

  DioException status(int code) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
    ),
  );

  DioException timeout() => DioException.connectionTimeout(
    timeout: const Duration(seconds: 5),
    requestOptions: RequestOptions(path: '/'),
  );

  void repond(Object? body) {
    when(() => api.getPlan(auth)).thenAnswer((_) async => httpOk(body));
  }

  void leve(Object error) {
    when(() => api.getPlan(auth)).thenThrow(error);
  }

  SyncPlanUnknownCause causeDe(SyncPlanState state) {
    expect(
      state,
      isA<SyncPlanUnknown>(),
      reason: 'attendu SyncPlanUnknown, reçu ${state.runtimeType}',
    );
    return (state as SyncPlanUnknown).cause;
  }

  group('load() — réseau', () {
    test(
      '200 + plan concordant → known, ET le plan est ÉCRIT en cache',
      () async {
        repond(planBody());

        final state = await repo.load();

        expect(state, isA<SyncPlanKnown>());
        expect((state as SyncPlanKnown).plan.subject, uidA);
        expect(state.plan.keys, ['socle']);

        // On relit `sync_meta` : le cache doit contenir le corps, et un
        // horodatage de récupération.
        final cache = await syncMeta.getCursor(cleA);
        expect(cache, isNotNull, reason: 'le plan doit être mis en cache');
        final decode = jsonDecode(cache!) as Map<String, dynamic>;
        expect(decode['subject'], uidA);
        expect(decode['planVersion'], 1);
        expect((decode['streams'] as List).single, isA<Map>());
        expect(await syncMeta.getSyncedAt(cleA), isNotNull);
      },
    );

    test(
      '200 + streams vide → EMPTY, jamais unknown (« rien à tirer » n\'est pas '
      '« on ne sait pas »)',
      () async {
        repond(planBody(streams: const <Object?>[]));

        final state = await repo.load();

        expect(state, isA<SyncPlanEmpty>());
        expect(state, isNot(isA<SyncPlanUnknown>()));
        expect((state as SyncPlanEmpty).plan.subject, uidA);
        expect(state.plan.streams, isEmpty);
        // Positivement identifié : il est mis en cache comme un plan connu.
        expect(await syncMeta.getCursor(cleA), isNotNull);
      },
    );

    test(
      'subject DISCORDANT → foreignSubject, et RIEN n\'est écrit en cache',
      () async {
        // Tablette partagée : le plan de B ne doit jamais servir à A.
        repond(planBody(subject: uidB));

        final state = await repo.load();

        expect(causeDe(state), SyncPlanUnknownCause.foreignSubject);
        expect(
          await syncMeta.getCursor(cleA),
          isNull,
          reason: 'le plan d\'un autre compte ne doit pas écraser le nôtre',
        );
        expect(await syncMeta.getSyncedAt(cleA), isNull);
      },
    );

    test(
      'un plan étranger n\'ÉCRASE PAS un plan valide déjà en cache',
      () async {
        repond(planBody());
        await repo.load();
        final avant = await syncMeta.getCursor(cleA);

        repond(planBody(subject: uidB, planVersion: 99));
        final state = await repo.load();

        expect(causeDe(state), SyncPlanUnknownCause.foreignSubject);
        expect(await syncMeta.getCursor(cleA), avant);
      },
    );

    test(
      'uid local ABSENT → absent, JAMAIS foreignSubject (la cause est locale)',
      () async {
        // Backend hérité sans revendication `uid` : conclure à la discordance
        // ferait basculer tout un parc en repli permanent.
        currentUser.clear();
        repond(planBody(subject: uidA));

        final state = await repo.load();

        expect(causeDe(state), SyncPlanUnknownCause.absent);
        expect(causeDe(state), isNot(SyncPlanUnknownCause.foreignSubject));
      },
    );

    test('uid local vide vaut uid absent, pas discordance', () async {
      currentUser.set('');
      repond(planBody(subject: uidA));

      expect(causeDe(await repo.load()), SyncPlanUnknownCause.absent);
    });

    test('200 + corps illisible → malformed, et RIEN en cache', () async {
      repond('<!DOCTYPE html><html><body>portail captif</body></html>');

      final state = await repo.load();

      expect(causeDe(state), SyncPlanUnknownCause.malformed);
      expect(
        await syncMeta.getCursor(cleA),
        isNull,
        reason: 'un repli ne doit pas se lire comme une synchro réussie',
      );
      expect(
        await syncMeta.getSyncedAt(cleA),
        isNull,
        reason: 'ni le plan, ni l\'horodatage de fraîcheur',
      );
    });

    test('200 + corps illisible n\'écrase pas le plan déjà en cache', () async {
      repond(planBody());
      await repo.load();
      final avant = await syncMeta.getCursor(cleA);

      repond('pas un plan du tout');
      final state = await repo.load();

      expect(causeDe(state), SyncPlanUnknownCause.malformed);
      expect(await syncMeta.getCursor(cleA), avant);
    });

    test(
      'un flux au mode inconnu n\'invalide pas le plan, et le CORPS BRUT est '
      'mis en cache (le flux écarté y survit)',
      () async {
        repond(
          planBody(
            streams: const <Object?>[
              {'key': 'socle', 'mode': 'BUNDLE', 'scope': 'school'},
              {'key': 'teleporteur', 'mode': 'TELEPORT', 'scope': 'school'},
            ],
          ),
        );

        final state = await repo.load();

        expect(state, isA<SyncPlanKnown>());
        expect((state as SyncPlanKnown).plan.keys, ['socle']);

        // LA TRACE SURVIT AU REPOSITORY, et c'est tout l'objet de ce test.
        // Le contrat dit « ignorer ce qu'on ne connaît pas, mais jamais sans
        // trace », et ce dépôt n'a aucun canal de log : l'état EST le canal.
        // Sans cette assertion, retirer `rejectedKeys` de `_stateOf` laisserait
        // la suite entièrement verte — les deux constructeurs ont un défaut.
        expect(state.rejectedKeys, {'teleporteur'});

        // C'est le corps brut qui est caché, pas le plan analysé : un APK
        // ultérieur qui apprendrait `TELEPORT` le retrouverait sans refetch.
        // (Cacher `jsonEncode(plan)` l'aurait perdu définitivement.)
        final cache = jsonDecode((await syncMeta.getCursor(cleA))!) as Map;
        expect((cache['streams'] as List).map((e) => (e as Map)['key']), [
          'socle',
          'teleporteur',
        ]);

        // Le rejeu depuis le cache RÉ-ANALYSE le corps brut : il retrouve donc
        // le même plan ET la même trace, sans nouvel aller-retour.
        final relu = await repo.loadCached();
        expect((relu as SyncPlanKnown).plan.keys, ['socle']);
        expect(relu.rejectedKeys, {'teleporteur'});
      },
    );
  });

  group('load() — le départage des échecs', () {
    test('404 → notDeployed (cas nominal du dégradé)', () async {
      leve(status(404));
      expect(causeDe(await repo.load()), SyncPlanUnknownCause.notDeployed);
    });

    test('401 → unauthorized', () async {
      leve(status(401));
      expect(causeDe(await repo.load()), SyncPlanUnknownCause.unauthorized);
    });

    test('403 → unauthorized', () async {
      leve(status(403));
      expect(causeDe(await repo.load()), SyncPlanUnknownCause.unauthorized);
    });

    test(
      '404 et 401 rendent leur cause DIRECTEMENT : le cache n\'est pas consulté',
      () async {
        // Le départage est délibéré : une route absente ou un refus ne seront
        // pas démentis par un cache venu du même serveur.
        repond(planBody());
        await repo.load();
        expect(await syncMeta.getCursor(cleA), isNotNull);

        leve(status(404));
        expect(causeDe(await repo.load()), SyncPlanUnknownCause.notDeployed);

        leve(status(401));
        expect(causeDe(await repo.load()), SyncPlanUnknownCause.unauthorized);

        leve(status(403));
        expect(causeDe(await repo.load()), SyncPlanUnknownCause.unauthorized);
      },
    );

    test('timeout → le CACHE est consulté et sert le plan', () async {
      repond(planBody());
      await repo.load();

      leve(timeout());
      final state = await repo.load();

      expect(
        state,
        isA<SyncPlanKnown>(),
        reason: 'un incident de transport laisse sa chance au cache',
      );
      expect((state as SyncPlanKnown).plan.subject, uidA);
    });

    test('500 → transport : le cache est consulté lui aussi', () async {
      repond(planBody());
      await repo.load();

      leve(status(500));

      expect(await repo.load(), isA<SyncPlanKnown>());
    });

    test('timeout SANS cache → absent (rien nulle part)', () async {
      leve(timeout());
      expect(causeDe(await repo.load()), SyncPlanUnknownCause.absent);
    });

    test(
      'timeout avec un cache ÉTRANGER → foreignSubject, pas known',
      () async {
        // Le cache est resoumis au même contrôle de `subject` qu'un plan frais.
        await syncMeta.setCursor(
          cleA,
          cursor: jsonEncode(planBody(subject: uidB)),
          syncedAt: 1,
        );

        leve(timeout());

        expect(causeDe(await repo.load()), SyncPlanUnknownCause.foreignSubject);
      },
    );
  });

  /// La jambe réseau **seule** (ADR-015 F9).
  ///
  /// Elle existe pour une raison unique et étroite : `load()` replie sur le
  /// cache et rend un `SyncPlanKnown`, verdict rigoureusement identique à une
  /// lecture fraîche. Un appelant qui doit savoir si sa relecture a **abouti** —
  /// pour retenter au cycle suivant plutôt que de croire son plan à jour — n'a
  /// rien à quoi s'accrocher. C'est ce manque qui rendait le « marqué à relire »
  /// inexprimable.
  ///
  /// D'où la ligne de partage que ce groupe verrouille : `null` = la jambe
  /// réseau n'a pas abouti, **retente** ; un état = un verdict a été obtenu,
  /// **n'insiste pas**.
  group('refreshFromNetwork()', () {
    test(
      '200 + plan concordant → rend l\'état, ET le cache est écrit',
      () async {
        repond(planBody());

        final state = await repo.refreshFromNetwork();

        expect(state, isA<SyncPlanKnown>());
        expect((state as SyncPlanKnown).plan.subject, uidA);
        expect(state.plan.keys, ['socle']);

        // Une relecture réussie sert aussi les démarrages hors ligne suivants :
        // la jambe réseau n'est pas un chemin de diagnostic à part, c'est le
        // chemin nominal du cycle.
        final cache = await syncMeta.getCursor(cleA);
        expect(cache, isNotNull, reason: 'le plan doit être mis en cache');
        expect(jsonDecode(cache!)['subject'], uidA);
        expect(await syncMeta.getSyncedAt(cleA), isNotNull);
      },
    );

    test(
      'timeout → NULL, et surtout PAS l\'état que load() aurait rendu depuis le '
      'cache',
      () async {
        // Le cache est peuplé et concordant : c'est précisément la situation où
        // les deux méthodes divergent, et la seule qui prouve quelque chose.
        repond(planBody());
        await repo.load();
        expect(await syncMeta.getCursor(cleA), isNotNull);

        leve(timeout());

        expect(
          await repo.refreshFromNetwork(),
          isNull,
          reason:
              'une relecture qui n\'a pas abouti doit se distinguer d\'une '
              'relecture réussie — sinon le drapeau « à relire » s\'éteint sur '
              'un échec, soit l\'inverse exact du comportement voulu',
        );
        // La contre-épreuve, dans le même souffle : `load()`, lui, sert le
        // cache et rend un état indistinguable d'une lecture fraîche.
        expect(await repo.load(), isA<SyncPlanKnown>());
      },
    );

    test(
      'timeout SANS cache → null aussi (le cache n\'est pas consulté)',
      () async {
        leve(timeout());

        expect(await repo.refreshFromNetwork(), isNull);
        // `load()` aurait rendu `absent` — un état, donc « verdict obtenu ».
        expect(causeDe(await repo.load()), SyncPlanUnknownCause.absent);
      },
    );

    test('500 → null : un incident de transport, pas un verdict', () async {
      leve(status(500));

      expect(await repo.refreshFromNetwork(), isNull);
    });

    test(
      'une erreur QUELCONQUE (pas une DioException) → null, sans lever',
      () async {
        // Pas de `response` à interroger : statut inconnu, donc transport, donc
        // « retente ». Et surtout : la méthode ne lève pas plus que `load()`.
        leve(const ErreurQuelconque());

        expect(await repo.refreshFromNetwork(), isNull);
      },
    );

    test(
      '404 → notDeployed, PAS null : le serveur a rendu son verdict',
      () async {
        // Cas nominal du dégradé — l'APK se met à jour indépendamment du back.
        // Le rendre `null` ferait retenter à chaque cycle, donc un timeout par
        // montage d'écran sur tout un parc dont le back n'est pas déployé.
        leve(status(404));

        final state = await repo.refreshFromNetwork();

        expect(state, isNotNull);
        expect(causeDe(state!), SyncPlanUnknownCause.notDeployed);
      },
    );

    test('401 → unauthorized, pas null', () async {
      leve(status(401));

      final state = await repo.refreshFromNetwork();

      expect(state, isNotNull);
      expect(causeDe(state!), SyncPlanUnknownCause.unauthorized);
    });

    test('403 → unauthorized, pas null', () async {
      // Le contrat promet « jamais 403 » : c'est une anomalie de déploiement,
      // pas un manque de droit — et retenter ne la lèvera pas.
      leve(status(403));

      final state = await repo.refreshFromNetwork();

      expect(state, isNotNull);
      expect(causeDe(state!), SyncPlanUnknownCause.unauthorized);
    });

    test(
      '404 / 401 / 403 ne consultent PAS le cache, même peuplé et valide',
      () async {
        repond(planBody());
        await repo.load();

        for (final code in [404, 401, 403]) {
          leve(status(code));
          final state = await repo.refreshFromNetwork();
          expect(
            state,
            isA<SyncPlanUnknown>(),
            reason: 'le $code doit rendre son verdict, pas le plan en cache',
          );
        }
      },
    );

    test(
      '200 + corps illisible → NULL : le portail captif est transitoire, pas un '
      'verdict — et RIEN en cache',
      () async {
        // ⚠️ L'attente s'est INVERSÉE, et c'est le correctif d'un défaut réel.
        //
        // Ce test figeait « c'est un corps reçu, donc un verdict : retenter en
        // boucle ne le changerait pas ». C'est faux précisément pour le cas
        // qu'il met en scène : une fois le portail franchi, le même GET aboutit.
        //
        // Rendre un état éteignait le drapeau « à relire » du porteur, donc
        // figeait le plan sur `malformed` pour TOUTE la session — et sous F5 un
        // plan inconnu rend la main à `requiredPermissions`, derrière une
        // pastille verte (`isDegraded` ignore ce cas). Le mécanisme entier
        // s'annulait sur l'incident le plus banal d'un wifi d'école.
        //
        // La ligne de partage n'est donc pas « a-t-on reçu un corps » mais
        // « une nouvelle tentative pourrait-elle donner autre chose ».
        repond('<!DOCTYPE html><html><body>portail captif</body></html>');

        final state = await repo.refreshFromNetwork();

        expect(
          state,
          isNull,
          reason: 'null = relecture non aboutie ⇒ le porteur retentera',
        );
        expect(
          await syncMeta.getCursor(cleA),
          isNull,
          reason: 'un repli ne doit pas se lire comme une synchro réussie',
        );
        expect(
          await syncMeta.getSyncedAt(cleA),
          isNull,
          reason: 'ni le plan, ni l\'horodatage de fraîcheur',
        );
      },
    );

    test('load() garde le diagnostic malformed : sans cache, il ne doit pas se '
        'dégrader en « absent »', () async {
      // La règle ci-dessus vaut pour `refreshFromNetwork` SEUL. Au premier
      // démarrage il n'y a pas de cache, et confondre « le serveur a répondu
      // n'importe quoi » avec « on n'a jamais rien reçu » perdrait la seule
      // trace dont dispose un dépôt sans logger.
      repond('<!DOCTYPE html><html><body>portail captif</body></html>');

      final state = await repo.load();

      expect(causeDe(state), SyncPlanUnknownCause.malformed);
    });

    test(
      'subject DISCORDANT → foreignSubject, et RIEN n\'est écrit en cache',
      () async {
        // Tablette partagée : sous F5 ce plan ne déciderait plus d'un affichage
        // mais de ce que le compte courant TIRE.
        repond(planBody(subject: uidB));

        final state = await repo.refreshFromNetwork();

        expect(state, isNotNull);
        expect(causeDe(state!), SyncPlanUnknownCause.foreignSubject);
        expect(
          await syncMeta.getCursor(cleA),
          isNull,
          reason: 'le plan d\'un autre compte ne doit pas écraser le nôtre',
        );
        expect(await syncMeta.getSyncedAt(cleA), isNull);
      },
    );

    test(
      '200 + streams vide → empty, pas null, et le plan est caché',
      () async {
        repond(planBody(streams: const <Object?>[]));

        final state = await repo.refreshFromNetwork();

        expect(state, isA<SyncPlanEmpty>());
        expect(state, isNot(isA<SyncPlanUnknown>()));
        expect(await syncMeta.getCursor(cleA), isNotNull);
      },
    );
  });

  group('loadCached()', () {
    test('cache absent → absent, sans toucher au réseau', () async {
      expect(causeDe(await repo.loadCached()), SyncPlanUnknownCause.absent);
      verifyNever(() => api.getPlan(any()));
    });

    test('cache présent et concordant → known', () async {
      await syncMeta.setCursor(
        cleA,
        cursor: jsonEncode(planBody()),
        syncedAt: 1,
      );

      final state = await repo.loadCached();

      expect(state, isA<SyncPlanKnown>());
      expect((state as SyncPlanKnown).plan.keys, ['socle']);
      verifyNever(() => api.getPlan(any()));
    });

    test('cache présent mais d\'un AUTRE subject → foreignSubject', () async {
      await syncMeta.setCursor(
        cleA,
        cursor: jsonEncode(planBody(subject: uidB)),
        syncedAt: 1,
      );

      expect(
        causeDe(await repo.loadCached()),
        SyncPlanUnknownCause.foreignSubject,
      );
    });

    test('cache CORROMPU (pas du JSON) → malformed, sans lever', () async {
      await syncMeta.setCursor(
        cleA,
        cursor: 'ceci n\'est pas du JSON {{{',
        syncedAt: 1,
      );

      expect(causeDe(await repo.loadCached()), SyncPlanUnknownCause.malformed);
    });

    test('cache = JSON valide mais pas un plan → malformed', () async {
      await syncMeta.setCursor(cleA, cursor: '{"hello":"world"}', syncedAt: 1);

      expect(causeDe(await repo.loadCached()), SyncPlanUnknownCause.malformed);
    });

    test('cache vide (chaîne vide) → absent, pas malformed', () async {
      await syncMeta.setCursor(cleA, cursor: '', syncedAt: 1);

      expect(causeDe(await repo.loadCached()), SyncPlanUnknownCause.absent);
    });

    test('cache d\'un plan sans flux → empty, jamais unknown', () async {
      await syncMeta.setCursor(
        cleA,
        cursor: jsonEncode(planBody(streams: const <Object?>[])),
        syncedAt: 1,
      );

      final state = await repo.loadCached();
      expect(state, isA<SyncPlanEmpty>());
      expect(state, isNot(isA<SyncPlanUnknown>()));
    });
  });

  group('la clé de cache est SCOPÉE PAR COMPTE', () {
    test(
      'deux uid ne partagent pas la ligne sync_meta : B ne lit pas le plan de A',
      () async {
        repond(planBody(subject: uidA));
        expect(await repo.load(), isA<SyncPlanKnown>());
        expect(await syncMeta.getCursor(cleA), isNotNull);

        // Même tablette, autre compte : la ligne de A n'est pas la sienne.
        currentUser.set(uidB);
        expect(
          await syncMeta.getCursor(cleB),
          isNull,
          reason: 'la clé de B ne doit exister sous aucune forme',
        );
        expect(causeDe(await repo.loadCached()), SyncPlanUnknownCause.absent);

        // Et le plan de A est intact : partitionner, pas purger.
        currentUser.set(uidA);
        expect(await repo.loadCached(), isA<SyncPlanKnown>());
      },
    );

    test('les deux plans coexistent sous leurs clés respectives', () async {
      repond(planBody(subject: uidA, planVersion: 1));
      await repo.load();

      currentUser.set(uidB);
      repond(planBody(subject: uidB, planVersion: 2));
      await repo.load();

      expect(jsonDecode((await syncMeta.getCursor(cleA))!)['planVersion'], 1);
      expect(jsonDecode((await syncMeta.getCursor(cleB))!)['planVersion'], 2);

      currentUser.set(uidA);
      final aRelu = await repo.loadCached();
      expect((aRelu as SyncPlanKnown).plan.planVersion, 1);
    });
  });

  group('le repository NE LÈVE JAMAIS', () {
    /// Le même repository, mais branché sur une base qui lève à chaque appel.
    SyncPlanRepositoryImpl repoSurBaseHS() => SyncPlanRepositoryImpl(
      api: api,
      syncMetaDao: const SyncMetaDao(BaseIndisponible()),
      currentUser: currentUser,
      requiredAuth: auth,
    );

    test('base indisponible → loadCached() rend absent, sans lever', () async {
      expect(
        causeDe(await repoSurBaseHS().loadCached()),
        SyncPlanUnknownCause.absent,
      );
    });

    test(
      'base indisponible + 200 valide → known quand même (cache best-effort)',
      () async {
        // Un cache non écrit coûte un aller-retour, il ne casse pas le cycle.
        repond(planBody());

        expect(await repoSurBaseHS().load(), isA<SyncPlanKnown>());
      },
    );

    test('base indisponible + timeout → absent, sans lever', () async {
      leve(timeout());

      expect(
        causeDe(await repoSurBaseHS().load()),
        SyncPlanUnknownCause.absent,
      );
    });

    test(
      'une API qui lève un objet QUELCONQUE (pas une DioException) → un état',
      () async {
        leve(const ErreurQuelconque());

        // Pas de `response` à interroger : `_statusOf` doit rendre null sans
        // lever, donc transport, donc repli sur le cache.
        expect(causeDe(await repo.load()), SyncPlanUnknownCause.absent);
      },
    );

    test('une API qui lève une String → un état, pas une exception', () async {
      leve('boom');

      expect(causeDe(await repo.load()), SyncPlanUnknownCause.absent);
    });

    test(
      'objet quelconque + cache valide → le cache sert (transport, pas verdict)',
      () async {
        await syncMeta.setCursor(
          cleA,
          cursor: jsonEncode(planBody()),
          syncedAt: 1,
        );

        leve(const ErreurQuelconque());

        expect(await repo.load(), isA<SyncPlanKnown>());
      },
    );
  });
}

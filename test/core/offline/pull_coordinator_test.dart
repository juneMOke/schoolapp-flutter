import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_holder.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_repository.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';

class MockConnectivity extends Mock implements Connectivity {}

/// Handler configurable qui compte ses appels.
class FakePullHandler implements PullHandler {
  FakePullHandler(
    this.resource,
    this._outcome, {
    this.requiredPermissions = const [Perm.schoolRead],
    this.isBaseline = false,
    this.journal,
  });

  @override
  final String resource;

  @override
  final List<Perm> requiredPermissions;

  /// Porté en CHAMP plutôt qu'en getter surchargé — comme
  /// `EnrollmentPullHandler`, seul porteur réel du drapeau. C'est ce qui permet
  /// d'opposer deux handlers identiques à ce seul détail près.
  @override
  final bool isBaseline;

  /// Journal partagé : chaque pull y inscrit sa ressource. Seule façon
  /// d'observer l'ordre RÉEL d'invocation — `calls` dit combien, jamais quand.
  final List<String>? journal;

  final PullOutcome _outcome;
  int calls = 0;

  @override
  Future<PullOutcome> pull() async {
    calls++;
    journal?.add(resource);
    return _outcome;
  }
}

/// Handler qui lève, pour vérifier l'isolation par ressource.
///
/// La ressource est paramétrable : l'abandon sur dépendance bloquante doit
/// valoir aussi bien pour un handler qui rend `error` que pour un handler qui
/// lève — le coordinateur inscrit les deux au même registre d'échecs, et une
/// seule des deux branches testée laisserait l'autre libre de diverger.
class ThrowingPullHandler implements PullHandler {
  ThrowingPullHandler([this.resource = 'boom']);

  @override
  final String resource;

  @override
  List<Perm> get requiredPermissions => const [Perm.schoolRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async => throw StateError('réseau coupé');
}

/// Sonde de crédentiels de test — répond, ou lève.
///
/// Le gate qu'elle alimente vivait dans cinq use cases d'hydratation, qui
/// s'en servaient pour justifier de contourner le coordinateur. Il a remonté
/// dans le corps de cycle avec eux ; sans fake ici, plus rien ne l'observerait.
class FakeCredentialsProbe implements SessionCredentialsProbe {
  FakeCredentialsProbe.answering(bool answer)
    : _answer = answer,
      _throws = false;

  FakeCredentialsProbe.throwing() : _answer = false, _throws = true;

  final bool _answer;
  final bool _throws;
  int calls = 0;

  @override
  Future<bool> canAuthenticate() async {
    calls++;
    if (_throws) throw StateError('coffre verrouillé');
    return _answer;
  }
}

/// Handler lent (bloque sur un [Completer]) — pour tester le verrou concurrent.
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

/// Repository de plan de test — rend l'état qu'on lui confie, sans réseau.
///
/// Compte ses appels : c'est par là qu'on observe que le plan est résolu **une
/// fois par cycle** et **jamais avant** les gardes connectivité / crédentiels.
/// Le lire plus tôt imposerait un aller-retour — ou son timeout — à chaque
/// montage d'écran hors connexion.
class FakeSyncPlanRepository implements SyncPlanRepository {
  FakeSyncPlanRepository(this.state);

  final SyncPlanState state;
  int refreshCalls = 0;
  int cachedCalls = 0;

  @override
  Future<SyncPlanState> load() async => state;

  @override
  Future<SyncPlanState> loadCached() async {
    cachedCalls++;
    return state;
  }

  /// La jambe que le porteur consulte en premier. Non-nulle ici : ces tests
  /// portent sur ce que le coordinateur FAIT d'un plan, pas sur la péremption
  /// du mémo — qui se teste au niveau du porteur.
  @override
  Future<SyncPlanState?> refreshFromNetwork() async {
    refreshCalls++;
    return state;
  }
}

/// Un [SyncPlan] réduit à ses clés.
///
/// `clientResource` est renseigné depuis l'alias, comme le serveur le ferait,
/// alors que le coordinateur ne le lit **jamais** : il repasse par `planKeyOf`.
/// C'est délibéré côté production — ce champ est analysé en mode tolérant, et
/// une omission serveur mettrait sinon les dix-neuf handlers hors plan. Le
/// renseigner juste ici garde le montage honnête sans rien prouver de faux.
SyncPlan planWithKeys(List<String> keys) => SyncPlan(
  planVersion: 1,
  subject: 'uid-serveur-1',
  onAbsence: 'ignore',
  streams: [
    for (final key in keys)
      SyncPlanFlow(
        key: key,
        clientResource: resourcesOf(key),
        mode: SyncFlowMode.keyset,
        scope: SyncFlowScope.school,
        reason: const ['socle'],
        dependsOn: const [],
      ),
  ],
);

/// Régime VALIDE : ces clés-là, et rien d'autre.
SyncPlanState planKnown(List<String> keys) =>
    SyncPlanState.known(planWithKeys(keys));

/// Régime VALIDE dont l'analyse a **écarté** des clés (mode ou scope inconnu de
/// cet APK). Elles ne sont PAS dans `plan.streams` — le parser les en a
/// retirées — mais elles sont nommées dans `rejectedKeys`.
SyncPlanState planKnownWithRejected(
  List<String> keys,
  Set<String> rejectedKeys,
) => SyncPlanState.known(planWithKeys(keys), rejectedKeys: rejectedKeys);

/// Régime VIDE : le serveur a répondu, et il n'y a rien à tirer.
///
/// ⚠️ À ne jamais confondre avec [SyncPlanState.unknown] : l'un ne tire rien,
/// l'autre tire tout ce que le registre en dur autorise.
///
/// [rejectedKeys] distingue les DEUX façons d'être vide, qui se ressemblent à
/// l'œil et n'ont rien à voir : « ce compte n'a droit à rien » (ensemble vide)
/// et « cet APK ne comprend plus un seul flux de ce que le serveur envoie »
/// (toutes les clés écartées à l'analyse). L'assistant les construisait
/// toujours sans clés — c'est précisément pourquoi aucun des tests du régime
/// vide n'attrapait le second cas.
SyncPlanState planEmptyState({Set<String> rejectedKeys = const {}}) =>
    SyncPlanState.empty(planWithKeys(const []), rejectedKeys: rejectedKeys);

/// Régime INCONNU : le repli sur le registre en dur.
SyncPlanState planUnknown([
  SyncPlanUnknownCause cause = SyncPlanUnknownCause.notDeployed,
]) => SyncPlanState.unknown(cause);

void main() {
  late MockConnectivity connectivity;
  late ConnectivityService service;

  setUp(() {
    connectivity = MockConnectivity();
    service = ConnectivityService(connectivity);
  });

  void goOnline() {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  }

  void goOffline() {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
  }

  PullCoordinator build() => PullCoordinator(connectivity: service);

  test('hors ligne : ne tire rien', () async {
    goOffline();
    final handler = FakePullHandler('classrooms', const PullOutcome.updated());
    final coord = build()..registerHandler(handler);
    final report = await coord.pullAll();
    expect(report.offline, isTrue);
    expect(handler.calls, 0);
  });

  test('en ligne : agrège updated / notModified / error', () async {
    goOnline();
    final coord = build()
      ..registerHandler(
        FakePullHandler('a', const PullOutcome.updated(upserted: 3)),
      )
      ..registerHandler(FakePullHandler('b', const PullOutcome.notModified()))
      ..registerHandler(FakePullHandler('c', const PullOutcome.error('KO')));
    final report = await coord.pullAll();
    expect(report.updated, 1);
    expect(report.notModified, 1);
    expect(report.failed, 1);
    expect(report.processed, 3);
  });

  test('isolation : un handler qui lève est compté en échec, les autres '
      'tournent quand même', () async {
    goOnline();
    final ok = FakePullHandler('a', const PullOutcome.updated());
    final coord = build()
      ..registerHandler(ThrowingPullHandler())
      ..registerHandler(ok);
    final report = await coord.pullAll();
    expect(report.failed, 1);
    expect(report.updated, 1);
    expect(ok.calls, 1);
  });

  test('registerHandler : même ressource → dernier gagne', () async {
    goOnline();
    final first = FakePullHandler('classrooms', const PullOutcome.updated());
    final second = FakePullHandler(
      'classrooms',
      const PullOutcome.notModified(),
    );
    final coord = build()
      ..registerHandler(first)
      ..registerHandler(second);
    final report = await coord.pullAll();
    expect(first.calls, 0);
    expect(second.calls, 1);
    expect(report.notModified, 1);
  });

  // ADR-015 K — l'ordre d'enregistrement EST l'ordre d'exécution, et c'est ce
  // que la DI offline exploite pour poser ses arêtes de dépendance (référentiel
  // avant les classes, créances avant paiements, barème avant les cours…). Rien
  // ne l'observait : le coordinateur pouvait passer à un `Set`, à un tri par
  // ressource ou à un `Future.wait` sans faire rougir un seul test, pendant que
  // quatre arêtes money-grade se cassaient en silence.
  group('ordre d\'exécution', () {
    test('les handlers sont tirés dans leur ordre d\'enregistrement', () async {
      goOnline();
      final journal = <String>[];
      final coord = build()
        ..registerHandler(
          FakePullHandler(
            'referentiel',
            const PullOutcome.updated(),
            journal: journal,
          ),
        )
        ..registerHandler(
          FakePullHandler(
            'creances',
            const PullOutcome.updated(),
            journal: journal,
          ),
        )
        ..registerHandler(
          FakePullHandler(
            'paiements',
            const PullOutcome.updated(),
            journal: journal,
          ),
        );

      await coord.pullAll();

      expect(journal, ['referentiel', 'creances', 'paiements']);
    });

    // Contre-épreuve indispensable : sans elle, le test ci-dessus resterait vert
    // si le coordinateur triait ses ressources par ordre alphabétique — les
    // trois noms y sont déjà. Ici l'ordre alphabétique donnerait l'inverse.
    test('ordre d\'enregistrement inverse ⇒ ordre de tir inverse '
        '(aucun tri caché)', () async {
      goOnline();
      final journal = <String>[];
      final coord = build()
        ..registerHandler(
          FakePullHandler(
            'paiements',
            const PullOutcome.updated(),
            journal: journal,
          ),
        )
        ..registerHandler(
          FakePullHandler(
            'creances',
            const PullOutcome.updated(),
            journal: journal,
          ),
        )
        ..registerHandler(
          FakePullHandler(
            'referentiel',
            const PullOutcome.updated(),
            journal: journal,
          ),
        );

      await coord.pullAll();

      expect(journal, ['paiements', 'creances', 'referentiel']);
    });

    // Le registre est une `LinkedHashMap` : réécrire une clé existante remplace
    // la valeur SANS la déplacer. Un registrar qui ré-enregistre une ressource
    // (rebinding, double appel) ne peut donc pas la faire remonter en tête — ce
    // qui déplacerait silencieusement une arête de dépendance.
    test(
      'un ré-enregistrement remplace le handler mais garde sa PLACE',
      () async {
        goOnline();
        final journal = <String>[];
        final premier = FakePullHandler(
          'creances',
          const PullOutcome.updated(),
          journal: journal,
        );
        final second = FakePullHandler(
          'creances',
          const PullOutcome.updated(),
          journal: journal,
        );
        final coord = build()
          ..registerHandler(premier)
          ..registerHandler(
            FakePullHandler(
              'paiements',
              const PullOutcome.updated(),
              journal: journal,
            ),
          )
          // Ré-enregistré APRÈS `paiements` : c'est bien le second qui tire, mais
          // toujours à la position du premier.
          ..registerHandler(second);

        await coord.pullAll();

        expect(journal, ['creances', 'paiements']);
        expect(premier.calls, 0);
        expect(second.calls, 1);
      },
    );

    // Une ressource sautée ne doit pas décaler les suivantes : le filtre retire
    // un maillon, il ne réordonne pas la chaîne.
    test('une ressource sautée ne réordonne pas les autres', () async {
      goOnline();
      final journal = <String>[];
      final coord =
          PullCoordinator(
              connectivity: service,
              permissions: CurrentPermissions()..set(const ['classroom.read']),
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
                journal: journal,
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'paiements',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.financePaymentRead],
                journal: journal,
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'classroom_members',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
                journal: journal,
              ),
            );

      await coord.pullAll();

      expect(journal, ['classrooms', 'classroom_members']);
    });
  });

  group('latestServerTimeMs (date de dernière synchro, badge)', () {
    test('agrège le MAX des serverTimeMs non-null observés', () async {
      goOnline();
      final coord = build()
        ..registerHandler(
          FakePullHandler(
            'a',
            const PullOutcome.updated(upserted: 1, serverTimeMs: 1000),
          ),
        )
        ..registerHandler(
          FakePullHandler(
            'b',
            const PullOutcome.updated(upserted: 1, serverTimeMs: 5000),
          ),
        )
        ..registerHandler(
          FakePullHandler('c', const PullOutcome.notModified()),
        );
      final report = await coord.pullAll();
      expect(report.latestServerTimeMs, 5000);
    });

    test('null si aucun handler ne rapporte de serverTimeMs', () async {
      goOnline();
      final coord = build()
        ..registerHandler(FakePullHandler('a', const PullOutcome.notModified()))
        ..registerHandler(FakePullHandler('b', const PullOutcome.error('KO')));
      final report = await coord.pullAll();
      expect(report.latestServerTimeMs, isNull);
    });

    test(
      'un handler en échec n\'empêche pas l\'agrégation des autres',
      () async {
        goOnline();
        final coord = build()
          ..registerHandler(ThrowingPullHandler())
          ..registerHandler(
            FakePullHandler(
              'ok',
              const PullOutcome.updated(upserted: 1, serverTimeMs: 42),
            ),
          );
        final report = await coord.pullAll();
        expect(report.latestServerTimeMs, 42);
      },
    );
  });

  test(
    'verrou : un second pullAll pendant un pull en cours est skipped',
    () async {
      goOnline();
      final gate = Completer<void>();
      final slow = SlowPullHandler(gate);
      final coord = build()..registerHandler(slow);

      // Le premier pullAll tourne (bloqué sur le gate) : _pulling est vrai.
      final first = coord.pullAll();
      expect(coord.isPulling, isTrue);

      final second = await coord.pullAll();
      expect(second.skipped, isTrue);

      gate.complete();
      final firstReport = await first;
      expect(firstReport.updated, 1);
      expect(slow.calls, 1);
    },
  );

  // ADR-014 — la boucle de pull tape des points d'entrée gardés par la
  // permission de lecture de leur domaine. Sans filtre, un compte au périmètre
  // étroit collectionnerait des 403 à chaque cycle, et l'état de synchro ne
  // distinguerait plus « pas le droit » d'un incident réseau.
  group('filtrage par permission', () {
    PullCoordinator buildWith(CurrentPermissions permissions) =>
        PullCoordinator(connectivity: service, permissions: permissions);

    test('ressource non autorisée : sautée, jamais appelée', () async {
      goOnline();
      final autorise = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final interdit = FakePullHandler(
        'payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          buildWith(CurrentPermissions()..set(const ['classroom.read']))
            ..registerHandler(autorise)
            ..registerHandler(interdit);

      final report = await coord.pullAll();

      expect(interdit.calls, 0);
      expect(autorise.calls, 1);
      expect(report.updated, 1);
      // Compté à part : ce n'est pas une panne, c'est un périmètre.
      expect(report.forbidden, 1);
      expect(report.failed, 0);
      expect(report.processed, 1);
    });

    test('ensemble vide : plus rien n\'est tiré', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final coord = buildWith(CurrentPermissions()..set(const []))
        ..registerHandler(handler);

      final report = await coord.pullAll();

      expect(handler.calls, 0);
      expect(report.forbidden, 1);
    });

    // `null` ≠ ensemble vide : tant que la couche auth n'a pas alimenté le
    // holder, on tire comme avant et c'est le serveur qui tranche. Filtrer là
    // couperait toute la synchro sur un simple trou d'alimentation.
    test('ensemble inconnu : on tire quand même', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final coord = buildWith(CurrentPermissions())..registerHandler(handler);

      final report = await coord.pullAll();

      expect(handler.calls, 1);
      expect(report.forbidden, 0);
      expect(report.updated, 1);
    });

    test('holder absent (coordinateur monté seul) : aucun filtrage', () async {
      goOnline();
      final handler = FakePullHandler(
        'payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord = build()..registerHandler(handler);

      expect((await coord.pullAll()).updated, 1);
      expect(handler.calls, 1);
    });

    test(
      'conjonction : une seule des deux permissions ne suffit pas',
      () async {
        goOnline();
        final handler = FakePullHandler(
          'referential',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.schoolRead, Perm.financeGridRead],
        );
        final coord = buildWith(
          CurrentPermissions()..set(const ['school.read']),
        )..registerHandler(handler);

        final report = await coord.pullAll();

        expect(handler.calls, 0);
        expect(report.forbidden, 1);
      },
    );

    test('une permission inconnue du client ne débloque rien', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final coord = buildWith(
        CurrentPermissions()..set(const ['classroom.readonly']),
      )..registerHandler(handler);

      expect((await coord.pullAll()).forbidden, 1);
      expect(handler.calls, 0);
    });

    // ── Le socle hors filtre (ADR-015 M) ──
    //
    // Le défaut corrigé : un compte dépourvu de `school.read` sautait le
    // référentiel Inscription. Sans années de référence en base, la porte de
    // navigation ne s'ouvre jamais — l'utilisateur reste sur l'écran d'amorçage
    // et la seule sortie est la déconnexion. La panne était totale et muette :
    // aucun échec, juste une ressource « sautée » de plus.
    //
    // Le socle se construit ici comme en production : `requiredPermissions`
    // reste déclaré (`school.read`), seul `isBaseline` change. Le traduire par
    // une exigence VIDE ferait l'inverse de ce qu'on attend — `canAccess`
    // refuse sur exigence vide, délibérément.
    FakePullHandler socle({
      PullOutcome outcome = const PullOutcome.updated(),
    }) => FakePullHandler(
      'enrollment_referential',
      outcome,
      requiredPermissions: const [Perm.schoolRead],
      isBaseline: true,
    );

    // LE test qui porte le correctif : l'ensemble VIDE est le cas où TOUT le
    // reste est sauté, donc celui où plus rien ne rattrape le socle.
    test(
      'socle : tiré alors que l\'ensemble des permissions est VIDE',
      () async {
        goOnline();
        final referentiel = socle(
          outcome: const PullOutcome.updated(upserted: 12),
        );
        final coord = buildWith(CurrentPermissions()..set(const []))
          ..registerHandler(referentiel);

        final report = await coord.pullAll();

        expect(referentiel.calls, 1);
        expect(report.updated, 1);
        expect(report.forbidden, 0);
      },
    );

    test(
      'socle : tiré alors que l\'ensemble ne contient pas son exigence',
      () async {
        goOnline();
        final referentiel = socle();
        // Un périmètre étroit mais non vide : ce compte lit les classes, pas
        // l'école. Il lui faut quand même son année de référence.
        final coord = buildWith(
          CurrentPermissions()..set(const ['classroom.read']),
        )..registerHandler(referentiel);

        final report = await coord.pullAll();

        expect(referentiel.calls, 1);
        expect(report.forbidden, 0);
      },
    );

    // Contre-épreuve : sans elle, les deux tests ci-dessus passeraient tout
    // aussi bien si le filtre de permission avait disparu ENTIÈREMENT. Les deux
    // handlers ne diffèrent que par `isBaseline` — même exigence, même ensemble
    // détenu, même cycle.
    test(
      'contre-épreuve : à exigence identique, le NON-socle est bien sauté',
      () async {
        goOnline();
        final referentiel = socle();
        final ordinaire = FakePullHandler(
          'enrollment_reenrollment_cohort',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.schoolRead],
        );
        final coord = buildWith(CurrentPermissions()..set(const []))
          ..registerHandler(referentiel)
          ..registerHandler(ordinaire);

        final report = await coord.pullAll();

        expect(referentiel.calls, 1);
        expect(ordinaire.calls, 0);
        expect(report.updated, 1);
        expect(report.forbidden, 1);
      },
    );

    // Le socle ne doit pas fausser le bilan : il est TIRÉ, pas toléré. Le
    // compter en `forbidden` afficherait une synchro dégradée à vie sur un
    // compte dont tout va bien — exactement le contresens que la docstring de
    // `forbidden` écarte.
    test('socle : compté dans processed, jamais dans forbidden, et un compte '
        'sans aucun droit n\'en devient pas dégradé', () async {
      goOnline();
      final referentiel = socle();
      final coord = buildWith(CurrentPermissions()..set(const []))
        ..registerHandler(referentiel);

      final report = await coord.pullAll();

      expect(report.processed, 1);
      expect(report.forbidden, 0);
      expect(report.failed, 0);
      expect(report.isDegraded, isFalse);
    });

    // Hors du filtre ne veut pas dire hors du reste : un socle qui échoue reste
    // un échec, il n'est pas absous par son drapeau.
    test(
      'socle en échec : compté en failed comme n\'importe quel flux',
      () async {
        goOnline();
        final referentiel = socle(outcome: const PullOutcome.error('KO'));
        final coord = buildWith(CurrentPermissions()..set(const []))
          ..registerHandler(referentiel);

        final report = await coord.pullAll();

        expect(referentiel.calls, 1);
        expect(report.failed, 1);
        expect(report.forbidden, 0);
        expect(report.isDegraded, isTrue);
      },
    );

    // Le drapeau lève la garde de PERMISSION, pas celle de connectivité : hors
    // ligne, on ne tire rien, socle compris. Une exception qui déborderait sur
    // la radio taperait le réseau à chaque cycle en mode avion.
    test('hors ligne : le socle ne fait pas exception non plus', () async {
      goOffline();
      final referentiel = socle();
      final coord = buildWith(CurrentPermissions()..set(const []))
        ..registerHandler(referentiel);

      final report = await coord.pullAll();

      expect(report.offline, isTrue);
      expect(referentiel.calls, 0);
    });
  });

  // ADR-015 F1a — les trois compteurs de ressources *sautées* du rapport
  // (`forbidden`, `outOfPlan`, `plannedNotPulled`) et le verdict `isDegraded`
  // qu'ils alimentent. Ce sont eux que la pastille de synchro consommera : ils
  // doivent rester séparés des ressources réellement tirées, et seuls ceux qui
  // dénoncent un *manque* doivent dégrader.
  group('compteurs de ressources sautées (ADR-015 F1a)', () {
    PullCoordinator buildWith(CurrentPermissions permissions) =>
        PullCoordinator(connectivity: service, permissions: permissions);

    // Ces deux compteurs ont une destination, pas encore de source : rien dans
    // `pullAll()` ne les alimente tant que le plan de synchro n'existe pas
    // (lots F2/F5). Le test fige cette attente pour que leur première montée en
    // charge soit un changement délibéré, jamais un effet de bord.
    test('cycle nominal : outOfPlan et plannedNotPulled restent à zéro, '
        'plannedNotPulledKeys vide — le plan n\'existe pas encore', () async {
      goOnline();
      final coord = build()
        ..registerHandler(
          FakePullHandler('a', const PullOutcome.updated(upserted: 2)),
        )
        ..registerHandler(
          FakePullHandler('b', const PullOutcome.notModified()),
        );

      final report = await coord.pullAll();

      expect(report.updated, 1);
      expect(report.notModified, 1);
      expect(report.outOfPlan, 0);
      expect(report.plannedNotPulled, 0);
      expect(report.plannedNotPulledKeys, isEmpty);
    });

    test('processed ne compte que les ressources réellement tirées, '
        'jamais celles sautées faute de permission', () async {
      goOnline();
      final autorise = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final aussiAutorise = FakePullHandler(
        'classroom-members',
        const PullOutcome.notModified(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final interdit = FakePullHandler(
        'payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          buildWith(CurrentPermissions()..set(const ['classroom.read']))
            ..registerHandler(autorise)
            ..registerHandler(aussiAutorise)
            ..registerHandler(interdit);

      final report = await coord.pullAll();

      expect(interdit.calls, 0);
      expect(report.forbidden, 1);
      // Trois handlers enregistrés, deux tirés : la ressource sautée n'a
      // produit ni donnée ni échec, elle n'a rien à faire dans `processed`.
      expect(report.processed, 2);
      expect(
        report.processed,
        report.updated + report.notModified + report.failed,
      );
    });

    // Les deux autres compteurs n'ayant pas encore de source dans `pullAll()`,
    // leur exclusion de `processed` se vérifie sur le rapport lui-même.
    test('aucun des trois compteurs de sautées n\'entre dans processed', () {
      const report = PullRunReport(
        updated: 2,
        notModified: 1,
        failed: 1,
        forbidden: 3,
        outOfPlan: 4,
        plannedNotPulled: 5,
        plannedNotPulledKeys: {'grades', 'timetable'},
      );

      expect(report.processed, 4); // 2 + 1 + 1, et rien d'autre.
    });

    group('isDegraded — table de vérité', () {
      // Un cycle déjà en vol n'a rien observé : il ne dit ni sain ni dégradé.
      test('rapport skipped ⇒ false', () {
        expect(const PullRunReport.skipped().isDegraded, isFalse);
      });

      // Même raison : hors ligne, rien n'a été tenté, donc rien n'est constaté.
      test('rapport offline ⇒ false', () {
        expect(const PullRunReport.offline().isDegraded, isFalse);
      });

      test('failed > 0 ⇒ true', () {
        expect(const PullRunReport(updated: 1, failed: 1).isDegraded, isTrue);
      });

      test('forbidden > 0 ⇒ true', () {
        expect(
          const PullRunReport(updated: 1, forbidden: 1).isDegraded,
          isTrue,
        );
      });

      test('plannedNotPulled > 0 ⇒ true', () {
        expect(
          const PullRunReport(
            updated: 1,
            plannedNotPulled: 1,
            plannedNotPulledKeys: {'grades'},
          ).isDegraded,
          isTrue,
        );
      });

      // Le cas le plus important du groupe : un flux hors du plan d'un profil
      // est le périmètre CORRECT de ce profil, pas un manque. L'y compter
      // afficherait une dégradation permanente à tout compte au périmètre
      // étroit — un enseignant verrait « partiellement à jour » à vie alors
      // que tout ce qui le concerne est descendu.
      test('outOfPlan > 0 SEUL ⇒ false', () {
        expect(
          const PullRunReport(updated: 3, outOfPlan: 7).isDegraded,
          isFalse,
        );
      });

      test('cycle entièrement sain (updated / notModified) ⇒ false', () {
        expect(
          const PullRunReport(updated: 4, notModified: 2).isDegraded,
          isFalse,
        );
      });
    });

    // Le chemin réel que la pastille consommera : une permission manquante
    // produit un rapport dégradé sans qu'aucun échec ne soit compté.
    test(
      'cycle réel avec une ressource sautée : forbidden == 1 et isDegraded',
      () async {
        goOnline();
        final autorise = FakePullHandler(
          'classrooms',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.classroomRead],
        );
        final interdit = FakePullHandler(
          'payments',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.financePaymentRead],
        );
        final coord =
            buildWith(CurrentPermissions()..set(const ['classroom.read']))
              ..registerHandler(autorise)
              ..registerHandler(interdit);

        final report = await coord.pullAll();

        expect(report.forbidden, 1);
        expect(report.failed, 0);
        expect(report.skipped, isFalse);
        expect(report.offline, isFalse);
        expect(report.isDegraded, isTrue);
      },
    );
  });

  // ADR-015 F6 — le chemin des écrans. Ces pulls-là partaient jusqu'ici en
  // direct sur les repositories : filtrés par AUCUN droit, hors de l'ordre
  // money-grade, sans rien diffuser. Ils passent maintenant par le même corps de
  // cycle que `pullAll`, et ce groupe est la preuve qu'ils n'ont pas emporté de
  // régime d'exception au passage.
  group('pullSubset (le chemin des écrans, ADR-015 F6)', () {
    test('ne tire QUE les ressources demandées', () async {
      goOnline();
      final demande = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final voisin = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
      );
      final coord = build()
        ..registerHandler(demande)
        ..registerHandler(voisin);

      final report = await coord.pullSubset(const {'classrooms'});

      expect(demande.calls, 1);
      expect(voisin.calls, 0);
      expect(report.updated, 1);
      expect(report.processed, 1);
    });

    // LE test de ce groupe. Un `Set` littéral au site d'appel n'a pas d'ordre
    // porteur : si le coordinateur itérait l'ensemble reçu, l'arête
    // créances → paiements dépendrait de la façon dont un développeur a tapé ses
    // accolades — et personne ne verrait jamais que l'ordre s'est inversé.
    // L'ensemble est donc écrit À L'ENVERS ici, exprès.
    test(
      'l\'ordre est celui du REGISTRE, jamais celui de l\'ensemble reçu',
      () async {
        goOnline();
        final journal = <String>[];
        final coord = build()
          ..registerHandler(
            FakePullHandler(
              'finance_student_charges',
              const PullOutcome.updated(),
              journal: journal,
            ),
          )
          ..registerHandler(
            FakePullHandler(
              'finance_payments',
              const PullOutcome.updated(),
              journal: journal,
            ),
          );

        await coord.pullSubset(const {
          'finance_payments',
          'finance_student_charges',
        });

        expect(journal, ['finance_student_charges', 'finance_payments']);
      },
    );

    // Un écran qui demande plus que ce que son APK sait tirer n'est pas une
    // panne : c'est un binaire en retard sur son plan. Il ne doit ni lever, ni
    // dégrader le rapport.
    test('une ressource demandée mais NON enregistrée est ignorée en '
        'silence', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = build()..registerHandler(handler);

      final report = await coord.pullSubset(const {
        'classrooms',
        'ressource_dun_apk_plus_recent',
      });

      expect(report.updated, 1);
      expect(report.failed, 0);
      expect(report.forbidden, 0);
      expect(report.blocked, 0);
      expect(report.plannedNotPulled, 0);
      expect(report.outcomes.keys, ['classrooms']);
      expect(report.isDegraded, isFalse);
    });

    // Pas même la pré-garde de connectivité : un écran dont aucune ressource
    // n'est enregistrée ne doit pas réveiller la radio à chaque montage.
    test('ensemble vide : aucun appel réseau', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = build()..registerHandler(handler);

      final report = await coord.pullSubset(const {});

      expect(handler.calls, 0);
      expect(report.processed, 0);
      verifyNever(() => connectivity.checkConnectivity());
    });

    test('ensemble dont aucune ressource n\'est enregistrée : aucun appel '
        'réseau non plus', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = build()..registerHandler(handler);

      final report = await coord.pullSubset(const {'inconnue', 'autre'});

      expect(handler.calls, 0);
      expect(report.processed, 0);
      verifyNever(() => connectivity.checkConnectivity());
    });

    // Le cœur du lot : ces pulls n'étaient filtrés par RIEN. Un enseignant qui
    // ouvrait un écran de caisse tirait les paiements, droits ou pas.
    test('le filtre de permission s\'applique aussi à pullSubset', () async {
      goOnline();
      final autorise = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final interdit = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          PullCoordinator(
              connectivity: service,
              permissions: CurrentPermissions()..set(const ['classroom.read']),
            )
            ..registerHandler(autorise)
            ..registerHandler(interdit);

      final report = await coord.pullSubset(const {
        'classrooms',
        'finance_payments',
      });

      expect(interdit.calls, 0);
      expect(report.forbidden, 1);
      expect(autorise.calls, 1);
      expect(report.updated, 1);
      expect(report.outcomes.containsKey('finance_payments'), isFalse);
    });

    // Et le socle y échappe, exactement comme dans `pullAll` : un écran monté
    // par un compte sans `school.read` doit quand même obtenir son année de
    // référence, faute de quoi la porte de navigation ne s'ouvre pas.
    test('le socle échappe au filtre dans pullSubset aussi', () async {
      goOnline();
      final referentiel = FakePullHandler(
        'enrollment_referential',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.schoolRead],
        isBaseline: true,
      );
      final ordinaire = FakePullHandler(
        'enrollment_reenrollment_cohort',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.schoolRead],
      );
      final coord =
          PullCoordinator(
              connectivity: service,
              permissions: CurrentPermissions()..set(const []),
            )
            ..registerHandler(referentiel)
            ..registerHandler(ordinaire);

      final report = await coord.pullSubset(const {
        'enrollment_referential',
        'enrollment_reenrollment_cohort',
      });

      expect(referentiel.calls, 1);
      expect(ordinaire.calls, 0);
      expect(report.updated, 1);
      expect(report.forbidden, 1);
    });

    // LE test qui garde la raison d'être du lot. Prendre le verrou de cycle
    // complet ici ferait qu'un écran monté pendant le cycle d'ouverture de
    // session recevrait « sauté » et resterait sur un cache froid — et cette
    // fenêtre tombe pile au démarrage, quand l'utilisateur ouvre son premier
    // écran.
    test('pullSubset ne prend PAS le verrou de cycle complet : un écran monté '
        'pendant un pullAll en vol tire quand même', () async {
      goOnline();
      final gate = Completer<void>();
      final lent = SlowPullHandler(gate);
      final ecran = FakePullHandler('classrooms', const PullOutcome.updated());
      final coord = build()
        ..registerHandler(lent)
        ..registerHandler(ecran);

      // Le cycle complet est en vol, bloqué sur son handler lent.
      final complet = coord.pullAll();
      expect(coord.isPulling, isTrue);

      final cible = await coord.pullSubset(const {'classrooms'});

      expect(cible.skipped, isFalse);
      expect(cible.updated, 1);
      expect(ecran.calls, 1);

      gate.complete();
      final rapportComplet = await complet;
      // Et le cycle complet a poursuivi sa route : deux tirs au total.
      expect(rapportComplet.updated, 2);
      expect(ecran.calls, 2);
    });
  });

  // ADR-015 F6 — le gate de crédentiels vivait dans cinq use cases
  // d'hydratation. Sans jetons utilisables, chaque ressource partirait en 401
  // pour rien ; il remonte ici avec eux, et vaut donc pour les deux points
  // d'entrée.
  group('gate crédentiels (ADR-015 F6)', () {
    PullCoordinator buildWith(SessionCredentialsProbe probe) =>
        PullCoordinator(connectivity: service, credentialsProbe: probe);

    test(
      'sonde à false : aucun handler appelé, rapport skipped (pullAll)',
      () async {
        goOnline();
        final handler = FakePullHandler(
          'classrooms',
          const PullOutcome.updated(),
        );
        final coord = buildWith(FakeCredentialsProbe.answering(false))
          ..registerHandler(handler);

        final report = await coord.pullAll();

        expect(report.skipped, isTrue);
        expect(handler.calls, 0);
        expect(report.processed, 0);
      },
    );

    test('sonde à false : aucun handler appelé, rapport skipped '
        '(pullSubset)', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = buildWith(FakeCredentialsProbe.answering(false))
        ..registerHandler(handler);

      final report = await coord.pullSubset(const {'classrooms'});

      expect(report.skipped, isTrue);
      expect(handler.calls, 0);
    });

    // Le drapeau du socle lève la garde de PERMISSION, pas celle des jetons :
    // sans `Authorization`, le référentiel se ferait refuser comme le reste.
    test('sonde à false : le socle ne fait pas exception', () async {
      goOnline();
      final referentiel = FakePullHandler(
        'enrollment_referential',
        const PullOutcome.updated(),
        isBaseline: true,
      );
      final coord = buildWith(FakeCredentialsProbe.answering(false))
        ..registerHandler(referentiel);

      expect((await coord.pullAll()).skipped, isTrue);
      expect(referentiel.calls, 0);
    });

    test('sonde absente (non injectée) : pas de gate, tout tire', () async {
      goOnline();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = build()..registerHandler(handler);

      expect((await coord.pullAll()).updated, 1);
      expect(handler.calls, 1);
    });

    // Fail-open : une sonde défaillante ne doit jamais devenir elle-même la
    // cause d'une synchronisation qui ne part plus. Le serveur reste de toute
    // façon la seule vraie frontière.
    test('sonde qui LÈVE : fail-open, tout tire', () async {
      goOnline();
      final sonde = FakeCredentialsProbe.throwing();
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = buildWith(sonde)..registerHandler(handler);

      final report = await coord.pullAll();

      expect(sonde.calls, 1);
      expect(report.skipped, isFalse);
      expect(report.updated, 1);
      expect(handler.calls, 1);
    });

    test('sonde à true : le cycle part normalement', () async {
      goOnline();
      final sonde = FakeCredentialsProbe.answering(true);
      final handler = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = buildWith(sonde)..registerHandler(handler);

      expect((await coord.pullAll()).updated, 1);
      expect(sonde.calls, 1);
    });
  });

  // ADR-015 F6 — la garde money-grade, portée jusqu'ici par
  // `SyncFinancePullsUseCase` seul. Les quatre arêtes n'ont PAS la même
  // gravité : une seule fait perdre de l'argent quand on passe outre, les trois
  // autres ne coûtent qu'un cycle imparfait. Les traiter à égalité perdrait des
  // données pour rien.
  group('abandon sur dépendance bloquée (ADR-015 F6)', () {
    test('créances en échec ⇒ paiements JAMAIS appelé, sinon le caissier '
        'réencaisse', () async {
      goOnline();
      final creances = FakePullHandler(
        'finance_student_charges',
        const PullOutcome.error('KO'),
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
      );
      final coord = build()
        ..registerHandler(creances)
        ..registerHandler(paiements);

      final report = await coord.pullAll();

      expect(paiements.calls, 0);
      // Compté en `blocked`, pas en `failed` : rien n'a échoué là, on s'est
      // abstenu. Les confondre ferait chercher une panne réseau qui n'existe pas.
      expect(report.blocked, 1);
      expect(report.failed, 1);
      expect(report.processed, 1);
      expect(report.outcomes.containsKey('finance_payments'), isFalse);
    });

    test('créances qui LÈVENT : même abandon', () async {
      goOnline();
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
      );
      final coord = build()
        ..registerHandler(ThrowingPullHandler('finance_student_charges'))
        ..registerHandler(paiements);

      final report = await coord.pullAll();

      expect(paiements.calls, 0);
      expect(report.blocked, 1);
      expect(report.failed, 1);
    });

    // Contre-épreuve indispensable : sans elle, le test ci-dessus resterait vert
    // si les paiements n'étaient JAMAIS tirés.
    test('contre-épreuve : créances OK ⇒ paiements bien appelé', () async {
      goOnline();
      final journal = <String>[];
      final creances = FakePullHandler(
        'finance_student_charges',
        const PullOutcome.updated(),
        journal: journal,
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        journal: journal,
      );
      final coord = build()
        ..registerHandler(creances)
        ..registerHandler(paiements);

      final report = await coord.pullAll();

      expect(journal, ['finance_student_charges', 'finance_payments']);
      expect(report.blocked, 0);
      expect(report.updated, 2);
      expect(report.succeeded('finance_payments'), isTrue);
    });

    // L'écran de caisse tire la paire par `pullSubset` : l'abandon doit y valoir
    // aussi, sans quoi le chemin le plus emprunté serait précisément celui qui
    // fait réencaisser.
    test('l\'abandon vaut aussi dans pullSubset', () async {
      goOnline();
      final creances = FakePullHandler(
        'finance_student_charges',
        const PullOutcome.error('KO'),
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
      );
      final coord = build()
        ..registerHandler(creances)
        ..registerHandler(paiements);

      final report = await coord.pullSubset(const {
        'finance_payments',
        'finance_student_charges',
      });

      expect(paiements.calls, 0);
      expect(report.blocked, 1);
    });

    // Les trois autres arêtes ne bloquent pas. Les classes échoueront
    // d'elles-mêmes faute de référentiel : renoncer n'éviterait qu'un appel,
    // alors que l'issue observée a de la valeur.
    test('arête NON bloquante : référentiel en échec n\'empêche pas les '
        'classes d\'être tentées', () async {
      goOnline();
      final referentiel = FakePullHandler(
        'enrollment_referential',
        const PullOutcome.error('KO'),
      );
      final classes = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
      );
      final coord = build()
        ..registerHandler(referentiel)
        ..registerHandler(classes);

      final report = await coord.pullAll();

      expect(classes.calls, 1);
      expect(report.blocked, 0);
      expect(report.failed, 1);
      expect(report.updated, 1);
    });

    // Les cours descendent très bien sans le barème : c'est la composition du
    // détail qui attendra un cycle. Y renoncer perdrait les cours pour rien.
    test('arête NON bloquante : barème en échec n\'empêche pas les cours '
        'd\'être tentés', () async {
      goOnline();
      final bareme = FakePullHandler(
        'academics_grades_referential',
        const PullOutcome.error('KO'),
      );
      final cours = FakePullHandler(
        'academics_cours',
        const PullOutcome.updated(),
      );
      final coord = build()
        ..registerHandler(bareme)
        ..registerHandler(cours);

      final report = await coord.pullAll();

      expect(cours.calls, 1);
      expect(report.blocked, 0);
    });

    // Et l'arête cours → évaluations, dernière des trois bénignes : sans cours
    // en base la boucle ne fait aucun appel, renoncer et poursuivre ont le même
    // effet, mais poursuivre laisse l'issue observable.
    test('arête NON bloquante : cours en échec n\'empêche pas les '
        'évaluations d\'être tentées', () async {
      goOnline();
      final cours = FakePullHandler(
        'academics_cours',
        const PullOutcome.error('KO'),
      );
      final evaluations = FakePullHandler(
        'academics_evaluations',
        const PullOutcome.notModified(),
      );
      final coord = build()
        ..registerHandler(cours)
        ..registerHandler(evaluations);

      final report = await coord.pullAll();

      expect(evaluations.calls, 1);
      expect(report.blocked, 0);
    });

    // Un échec en AVAL ne remonte pas : seule l'arête déclarée bloque, et
    // seulement dans son sens.
    test('paiements en échec ne bloquent rien en retour', () async {
      goOnline();
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.error('KO'),
      );
      final creances = FakePullHandler(
        'finance_student_charges',
        const PullOutcome.updated(),
      );
      // Enregistrées à l'envers exprès : ici l'ordre du registre est le seul en
      // vigueur, et il place les paiements d'abord.
      final coord = build()
        ..registerHandler(paiements)
        ..registerHandler(creances);

      final report = await coord.pullAll();

      expect(creances.calls, 1);
      expect(report.blocked, 0);
    });

    test('blocked entre dans isDegraded, jamais dans failed ni processed', () {
      const report = PullRunReport(updated: 2, blocked: 1);

      expect(report.isDegraded, isTrue);
      expect(report.failed, 0);
      expect(report.processed, 2);
    });
  });

  // ADR-015 F6 — les agrégats ne suffisent pas à un écran qui a demandé un
  // sous-ensemble : il veut savoir si SA ressource est passée, pas si le cycle
  // global s'est bien terminé.
  group('issues par ressource (outcomes / succeeded)', () {
    test('outcomes porte l\'issue de chaque ressource TENTÉE, et aucune de '
        'celles qui ont été sautées', () async {
      goOnline();
      final coord =
          PullCoordinator(
              connectivity: service,
              permissions: CurrentPermissions()
                ..set(const [
                  'classroom.read',
                  'finance.charge.read',
                  'finance.payment.read',
                ]),
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'classroom_members',
                const PullOutcome.notModified(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            // Échoue → et bloque les paiements, qui n'auront donc pas d'issue.
            ..registerHandler(
              FakePullHandler(
                'finance_student_charges',
                const PullOutcome.error('KO'),
                requiredPermissions: const [Perm.financeChargeRead],
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'finance_payments',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.financePaymentRead],
              ),
            )
            // Sautée faute de droit : sautée n'est pas tentée.
            ..registerHandler(
              FakePullHandler(
                'academics_notes',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.academicsGradeRead],
              ),
            );

      final report = await coord.pullAll();

      expect(report.outcomes, {
        'classrooms': PullResult.updated,
        'classroom_members': PullResult.notModified,
        'finance_student_charges': PullResult.error,
      });
      expect(report.forbidden, 1);
      expect(report.blocked, 1);
    });

    test('succeeded : vrai sur updated et sur notModified', () async {
      goOnline();
      final coord = build()
        ..registerHandler(
          FakePullHandler('classrooms', const PullOutcome.updated(upserted: 3)),
        )
        ..registerHandler(
          FakePullHandler('classroom_members', const PullOutcome.notModified()),
        );

      final report = await coord.pullSubset(const {
        'classrooms',
        'classroom_members',
      });

      expect(report.succeeded('classrooms'), isTrue);
      // « Rien de neuf » est un succès : le cache est à jour, c'est tout ce que
      // l'écran demandait.
      expect(report.succeeded('classroom_members'), isTrue);
    });

    // Les trois `false` que l'appelant n'a pas à distinguer : aucun des trois
    // n'autorise à annoncer un cache à jour.
    test('succeeded : faux sur error, sur une ressource sautée et sur une '
        'ressource jamais demandée', () async {
      goOnline();
      final coord =
          PullCoordinator(
              connectivity: service,
              permissions: CurrentPermissions()..set(const ['classroom.read']),
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.error('KO'),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'finance_payments',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.financePaymentRead],
              ),
            );

      final report = await coord.pullAll();

      expect(report.succeeded('classrooms'), isFalse);
      expect(report.succeeded('finance_payments'), isFalse);
      expect(report.succeeded('academics_notes'), isFalse);
    });

    test(
      'succeeded : faux sur toute ressource d\'un cycle hors ligne',
      () async {
        goOffline();
        final coord = build()
          ..registerHandler(
            FakePullHandler('classrooms', const PullOutcome.updated()),
          );

        final report = await coord.pullSubset(const {'classrooms'});

        expect(report.offline, isTrue);
        expect(report.succeeded('classrooms'), isFalse);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════
  // ADR-015 F5 — LE PLAN DEVIENT L'AUTORITÉ DE PÉRIMÈTRE
  //
  // `requiredPermissions` cesse d'être l'autorité pour devenir le filtre du
  // seul mode dégradé. Ce qui suit vérifie les TROIS régimes du `switch` de
  // substitution, et surtout qu'il s'agit bien d'une substitution.
  // ════════════════════════════════════════════════════════════════════════

  /// Un coordinateur dont le plan est celui-ci.
  ///
  /// Le porteur est monté ici comme en production — repository + abonnement aux
  /// permissions — plutôt que par un double du porteur : c'est la chaîne réelle
  /// qui doit être observée, et un faux porteur ne dirait rien de l'ordre entre
  /// les gardes et la résolution du plan.
  PullCoordinator plannedCoordinator(
    SyncPlanState state, {
    CurrentPermissions? permissions,
    FakeSyncPlanRepository? repository,
    SessionCredentialsProbe? credentialsProbe,
  }) => PullCoordinator(
    connectivity: service,
    permissions: permissions,
    credentialsProbe: credentialsProbe,
    planHolder: SyncPlanHolder(
      repository: repository ?? FakeSyncPlanRepository(state),
      permissions: permissions,
    ),
  );

  group('un flux ÉCARTÉ À L\'ANALYSE ne s\'arrête jamais en silence', () {
    // Trouvé en revue, reproduit par sonde, et c'était le pire défaut du lot.
    //
    // Quand le serveur introduit un `mode` ou un `scope` que cet APK ne connaît
    // pas, le parser retire le flux de `plan.streams` et le nomme dans
    // `rejectedKeys` — le contrat l'exige ainsi : « ignorer sans erreur, mais
    // jamais sans trace ».
    //
    // Sauf que la clé disparue de `plan.streams`, `_covers` la ratait, donc elle
    // tombait en `outOfPlan` — délibérément exclu de `isDegraded`. Résultat : le
    // flux s'arrêtait TOTALEMENT sur tout le parc, avec une pastille verte et
    // aucune trace. `rejectedKeys` était calculé depuis le lot F2 et lu par
    // personne.
    test(
      'sa clé est NOMMÉE dans plannedNotPulledKeys, et la pastille le dit',
      () async {
        goOnline();
        final creances = FakePullHandler(
          'finance_student_charges',
          const PullOutcome.updated(),
        );
        final coordinator = plannedCoordinator(
          planKnownWithRejected(
            const [SyncPlanKeys.financePayments],
            const {SyncPlanKeys.financeStudentCharges},
          ),
        )..registerHandler(creances);

        final report = await coordinator.pullAll();

        expect(creances.calls, 0, reason: 'le flux écarté n\'est pas tiré');
        expect(
          report.plannedNotPulledKeys,
          contains(SyncPlanKeys.financeStudentCharges),
          reason: 'sans le nom, personne ne saura JAMAIS lequel s\'est arrêté',
        );
        expect(
          report.isDegraded,
          isTrue,
          reason:
              'un flux planifié qui ne descend plus n\'est pas un périmètre '
              'correct : la pastille doit le dire',
        );
      },
    );

    test('un plan sans clé écartée ne déclare rien — contre-épreuve', () async {
      goOnline();
      final coordinator =
          plannedCoordinator(planKnown(const [SyncPlanKeys.financePayments]))
            ..registerHandler(
              FakePullHandler('finance_payments', const PullOutcome.updated()),
            );

      final report = await coordinator.pullAll();

      expect(report.plannedNotPulledKeys, isEmpty);
      expect(report.isDegraded, isFalse);
    });
  });

  group('le plan est l\'autorité de périmètre — régime VALIDE (ADR-015 F5)', () {
    // ─────────────────────────────────────────────────────────────────────
    // LE TEST QUI PORTE TOUT LE LOT.
    //
    // Un montage où l'union et la substitution donnent le même résultat ne
    // prouve rien : si le plan et le registre en dur sont d'accord, les deux
    // règles tirent la même chose et le test resterait vert sur la mauvaise.
    //
    // Le seul discriminant est une ressource **hors plan mais localement
    // LISIBLE** : « planifié OU lisible » la tirerait, « planifié, point » ne
    // la tire pas. C'est exactement la forme que D-03 interdit, et celle qu'une
    // V1 de ce plan contenait.
    // ─────────────────────────────────────────────────────────────────────
    test('SUBSTITUTION, jamais union : une ressource HORS PLAN mais localement '
        'LISIBLE n\'est PAS tirée', () async {
      goOnline();
      // Le compte détient bel et bien `classroom.read` : sous l'ancienne
      // autorité, les classes descendaient. Le plan, lui, ne les porte pas.
      final horsPlanMaisLisible = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final auPlan = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planKnown(const [SyncPlanKeys.financePayments]),
              permissions: CurrentPermissions()
                ..set(const ['classroom.read', 'finance.payment.read']),
            )
            ..registerHandler(horsPlanMaisLisible)
            ..registerHandler(auPlan);

      final report = await coord.pullAll();

      // L'union aurait tiré les classes. La substitution non.
      expect(horsPlanMaisLisible.calls, 0);
      expect(report.outOfPlan, 1);
      // Et le flux planifié, lui, est bien passé — sans quoi le test serait vert
      // pour la mauvaise raison (un coordinateur qui ne tire plus rien).
      expect(auPlan.calls, 1);
      expect(report.updated, 1);
      // Hors plan n'est pas « pas le droit » : les deux compteurs ne se
      // mélangent jamais.
      expect(report.forbidden, 0);
    });

    // Le symétrique, et le GAIN du lot (F-I9) : aucun flux d'un plan valide
    // n'est écarté par une règle locale. `requiredPermissions` est une copie
    // durcie du modèle de droits, embarquée dans l'APK ; elle annulait en
    // silence ce que le serveur accorde par entraînement.
    test('une ressource PLANIFIÉE mais NON lisible localement est bien '
        'tirée', () async {
      goOnline();
      final auPlanNonLisible = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord = plannedCoordinator(
        planKnown(const [SyncPlanKeys.financePayments]),
        // Le compte ne détient PAS `finance.payment.read` côté client.
        permissions: CurrentPermissions()..set(const ['classroom.read']),
      )..registerHandler(auPlanNonLisible);

      final report = await coord.pullAll();

      expect(auPlanNonLisible.calls, 1);
      expect(report.updated, 1);
      expect(report.forbidden, 0);
    });

    test('seuls les flux du plan sont tirés, les autres comptent en '
        'outOfPlan', () async {
      goOnline();
      final journal = <String>[];
      final coord =
          plannedCoordinator(
              planKnown(const [SyncPlanKeys.classroomClassrooms]),
              permissions: CurrentPermissions()
                ..set(const ['classroom.read', 'attendance.read']),
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
                journal: journal,
              ),
            )
            // Les deux suivantes sont lisibles localement : seul le plan les
            // écarte.
            ..registerHandler(
              FakePullHandler(
                'classroom_members',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
                journal: journal,
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'attendance',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.attendanceRead],
                journal: journal,
              ),
            );

      final report = await coord.pullAll();

      expect(journal, ['classrooms']);
      expect(report.outOfPlan, 2);
      expect(report.updated, 1);
      expect(report.forbidden, 0);
    });

    // ─────────────────────────────────────────────────────────────────────
    // F-I9, L'INVARIANT CENTRAL : sous un plan valide, AUCUN flux planifié
    // n'est écarté par une règle locale. L'ensemble de permissions VIDE est le
    // montage extrême — c'est celui où l'ancienne autorité refusait TOUT.
    // ─────────────────────────────────────────────────────────────────────
    test('F-I9 : un plan portant TOUTES les clés, avec un ensemble de '
        'permissions VIDE, tire TOUS les handlers', () async {
      goOnline();
      final handlers = <FakePullHandler>[];
      final coord = plannedCoordinator(
        planKnown(kSyncPlanAliases.keys.toList(growable: false)),
        // Aucun droit du tout. Sous `requiredPermissions`, les dix-neuf
        // ressources seraient sautées.
        permissions: CurrentPermissions()..set(const []),
      );
      for (final resource in kSyncPlanAliases.values.expand((r) => r)) {
        final handler = FakePullHandler(
          resource,
          const PullOutcome.updated(upserted: 1),
        );
        handlers.add(handler);
        coord.registerHandler(handler);
      }

      final report = await coord.pullAll();

      expect(handlers.every((h) => h.calls == 1), isTrue);
      expect(report.forbidden, 0);
      expect(report.outOfPlan, 0);
      expect(report.blocked, 0);
      expect(report.plannedNotPulled, 0);
      expect(report.processed, handlers.length);
      expect(report.isDegraded, isFalse);
    });

    test('outOfPlan n\'entre ni dans processed ni dans isDegraded — c\'est le '
        'périmètre correct, pas un manque', () async {
      goOnline();
      final coord =
          plannedCoordinator(
              planKnown(const [SyncPlanKeys.classroomClassrooms]),
              permissions: CurrentPermissions()
                ..set(const [
                  'classroom.read',
                  'finance.payment.read',
                  'academics.grade.read',
                ]),
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'finance_payments',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.financePaymentRead],
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'academics_notes',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.academicsGradeRead],
              ),
            );

      final report = await coord.pullAll();

      expect(report.outOfPlan, 2);
      expect(report.processed, 1);
      expect(report.failed, 0);
      expect(report.forbidden, 0);
      // Un enseignant au périmètre étroit verrait sinon « partiellement à
      // jour » à vie, alors que tout ce qui le concerne est descendu.
      expect(report.isDegraded, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────
    // ARBITRAGE ASSUMÉ : une ressource hors plan ne bloque PAS son aval
    // money-grade. Un flux hors du plan est le périmètre décidé par le serveur,
    // pas un amont en panne — l'inscrire au registre des inexploitables ferait
    // écarter un flux PLANIFIÉ par une règle locale, ce que F-I9 interdit
    // frontalement. F-I9 prime donc sur l'arête.
    // ─────────────────────────────────────────────────────────────────────
    test('une ressource HORS PLAN ne bloque pas son aval money-grade : un plan '
        'portant les paiements sans les créances tire bien les '
        'paiements', () async {
      goOnline();
      final creances = FakePullHandler(
        'finance_student_charges',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financeChargeRead],
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planKnown(const [SyncPlanKeys.financePayments]),
              permissions: CurrentPermissions()
                ..set(const ['finance.charge.read', 'finance.payment.read']),
            )
            ..registerHandler(creances)
            ..registerHandler(paiements);

      final report = await coord.pullAll();

      expect(creances.calls, 0);
      expect(report.outOfPlan, 1);
      expect(paiements.calls, 1);
      expect(report.blocked, 0);
      expect(report.updated, 1);
    });

    // Contre-épreuve : l'arête n'a pas disparu pour autant. Un amont PLANIFIÉ
    // qui ÉCHOUE bloque toujours son aval — c'est le cas où le caissier
    // réencaisserait.
    test('contre-épreuve : un amont PLANIFIÉ qui échoue bloque toujours son '
        'aval', () async {
      goOnline();
      final creances = FakePullHandler(
        'finance_student_charges',
        const PullOutcome.error('KO'),
        requiredPermissions: const [Perm.financeChargeRead],
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planKnown(const [
                SyncPlanKeys.financeStudentCharges,
                SyncPlanKeys.financePayments,
              ]),
              permissions: CurrentPermissions()..set(const []),
            )
            ..registerHandler(creances)
            ..registerHandler(paiements);

      final report = await coord.pullAll();

      expect(creances.calls, 1);
      expect(paiements.calls, 0);
      expect(report.blocked, 1);
      expect(report.failed, 1);
      expect(report.outOfPlan, 0);
    });

    // Un handler que la table d'alias ne connaît pas : aucune clé ne pourra
    // jamais le désigner. C'est un défaut de contrat, pas un périmètre — mais
    // sous un plan valide il est bel et bien hors plan.
    test('un handler dont planKeyOf rend null est hors plan', () async {
      goOnline();
      final inconnue = FakePullHandler(
        'ressource_absente_de_la_table_dalias',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final connue = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final coord =
          plannedCoordinator(
              planKnown(const [SyncPlanKeys.classroomClassrooms]),
              permissions: CurrentPermissions()..set(const ['classroom.read']),
            )
            ..registerHandler(inconnue)
            ..registerHandler(connue);

      final report = await coord.pullAll();

      expect(inconnue.calls, 0);
      expect(report.outOfPlan, 1);
      expect(connue.calls, 1);
    });

    // Une clé au plan qu'aucun handler ne couvre : une clé mal orthographiée de
    // part et d'autre suffit, et sous ce lot ce n'est plus une dégradation,
    // c'est l'arrêt total de ce flux. D'où les clés NOMMÉMENT — « un flux
    // manque » n'a jamais permis de trouver lequel.
    test('plannedNotPulled : une clé au plan sans handler enregistré est '
        'comptée ET nommée', () async {
      goOnline();
      final coord =
          plannedCoordinator(
            planKnown(const [
              SyncPlanKeys.classroomClassrooms,
              SyncPlanKeys.academicsNotes,
            ]),
            permissions: CurrentPermissions()..set(const ['classroom.read']),
          )..registerHandler(
            FakePullHandler(
              'classrooms',
              const PullOutcome.updated(),
              requiredPermissions: const [Perm.classroomRead],
            ),
          );

      final report = await coord.pullAll();

      expect(report.plannedNotPulled, 1);
      expect(report.plannedNotPulledKeys, {SyncPlanKeys.academicsNotes});
      // Défaut de contrat : celui-là dégrade, contrairement à `outOfPlan`.
      expect(report.isDegraded, isTrue);
    });

    // ⚠️ Le piège du compteur : mesuré contre la SÉLECTION du cycle, un
    // `pullSubset` d'une ressource déclarerait les dix-sept autres clés
    // manquantes — donc une pastille dégradée à CHAQUE montage d'écran, sur un
    // écran parfaitement sain.
    test('plannedNotPulled est calculé contre le REGISTRE COMPLET, jamais '
        'contre la sélection : un pullSubset d\'une ressource ne déclare pas '
        'les autres clés manquantes', () async {
      goOnline();
      final classes = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final coord =
          plannedCoordinator(
              planKnown(const [
                SyncPlanKeys.classroomClassrooms,
                SyncPlanKeys.classroomMembers,
                SyncPlanKeys.financePayments,
              ]),
              permissions: CurrentPermissions()..set(const ['classroom.read']),
            )
            ..registerHandler(classes)
            ..registerHandler(
              FakePullHandler(
                'classroom_members',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'finance_payments',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.financePaymentRead],
              ),
            );

      final report = await coord.pullSubset(const {'classrooms'});

      expect(classes.calls, 1);
      expect(report.plannedNotPulled, 0);
      expect(report.plannedNotPulledKeys, isEmpty);
      expect(report.isDegraded, isFalse);
    });

    // Contre-épreuve du précédent : sans elle, il resterait vert si le compteur
    // avait purement disparu du chemin `pullSubset`.
    test('contre-épreuve : en pullSubset aussi, une clé qu\'AUCUN handler du '
        'registre ne couvre est bien comptée', () async {
      goOnline();
      final coord =
          plannedCoordinator(
            planKnown(const [
              SyncPlanKeys.classroomClassrooms,
              SyncPlanKeys.academicsNotes,
            ]),
            permissions: CurrentPermissions()..set(const ['classroom.read']),
          )..registerHandler(
            FakePullHandler(
              'classrooms',
              const PullOutcome.updated(),
              requiredPermissions: const [Perm.classroomRead],
            ),
          );

      final report = await coord.pullSubset(const {'classrooms'});

      expect(report.plannedNotPulled, 1);
      expect(report.plannedNotPulledKeys, {SyncPlanKeys.academicsNotes});
    });
  });

  // Le contrat promet qu'un plan n'est JAMAIS vide — il contient au minimum le
  // socle. Ce régime est donc un serveur qui se contredit ; il est compté
  // plutôt que subi en silence.
  group('le plan est l\'autorité de périmètre — régime VIDE (ADR-015 F5)', () {
    test('aucun handler non-socle n\'est tiré', () async {
      goOnline();
      final classes = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planEmptyState(),
              // Périmètre large : seul le plan vide arrête le cycle.
              permissions: CurrentPermissions()
                ..set(const ['classroom.read', 'finance.payment.read']),
            )
            ..registerHandler(classes)
            ..registerHandler(paiements);

      final report = await coord.pullAll();

      expect(classes.calls, 0);
      expect(paiements.calls, 0);
      expect(report.processed, 0);
      // Ni « pas le droit » ni « hors périmètre » : c'est le plan entier qui
      // est vide, et le rapport le dit par son propre drapeau.
      expect(report.forbidden, 0);
      expect(report.outOfPlan, 0);
    });

    // Sans ce drapeau, la panne la plus TOTALE serait la plus SILENCIEUSE : la
    // tablette ne tire plus rien, `outOfPlan` est exclu d'`isDegraded` par
    // construction, et la pastille resterait verte.
    test('planEmpty est vrai, et isDegraded aussi', () async {
      goOnline();
      final coord =
          plannedCoordinator(
            planEmptyState(),
            permissions: CurrentPermissions()..set(const ['classroom.read']),
          )..registerHandler(
            FakePullHandler(
              'classrooms',
              const PullOutcome.updated(),
              requiredPermissions: const [Perm.classroomRead],
            ),
          );

      final report = await coord.pullAll();

      expect(report.planEmpty, isTrue);
      expect(report.isDegraded, isTrue);
      expect(report.failed, 0);
    });

    test('planEmpty vaut aussi pour pullSubset', () async {
      goOnline();
      final classes = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final coord = plannedCoordinator(
        planEmptyState(),
        permissions: CurrentPermissions()..set(const ['classroom.read']),
      )..registerHandler(classes);

      final report = await coord.pullSubset(const {'classrooms'});

      expect(classes.calls, 0);
      expect(report.planEmpty, isTrue);
      expect(report.isDegraded, isTrue);
    });

    test('un plan vide PARCE QUE tout a été écarté à l\'analyse nomme les clés '
        'fautives — sinon « rien à tirer » et « je ne comprends plus ce serveur » '
        'se ressemblent', () async {
      goOnline();
      final classes = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      // Le serveur a bien envoyé des flux ; l'analyse les a TOUS retirés
      // (un `mode` renommé, un `scope` neuf déployé d'un coup), donc
      // `plan.streams` est vide et l'état est VIDE, pas connu.
      final coord = plannedCoordinator(
        planEmptyState(
          rejectedKeys: const {'classroom.rosters', 'finance.payments'},
        ),
        permissions: CurrentPermissions()..set(const ['classroom.read']),
      )..registerHandler(classes);

      final report = await coord.pullAll();

      expect(classes.calls, 0);
      expect(report.planEmpty, isTrue);
      expect(report.isDegraded, isTrue);
      // Le cœur du test : le parc s'arrête TOTALEMENT, et le rapport doit
      // dire pourquoi. Sans ces clés il annonce « plan vide », ce qui envoie
      // chercher un serveur qui n'aurait rien renvoyé alors que le désaccord
      // est de contrat.
      expect(report.plannedNotPulledKeys, {
        'classroom.rosters',
        'finance.payments',
      });
      expect(report.plannedNotPulled, 2);
    });

    test(
      'un plan vide SANS clé écartée ne nomme rien (le compte sans droits)',
      () async {
        goOnline();
        final coord =
            plannedCoordinator(
              planEmptyState(),
              permissions: CurrentPermissions()..set(const ['classroom.read']),
            )..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            );

        final report = await coord.pullAll();

        expect(report.planEmpty, isTrue);
        expect(report.plannedNotPulledKeys, isEmpty);
        expect(report.plannedNotPulled, 0);
      },
    );
  });

  // Le mode dégradé — aujourd'hui encore le plus courant, tant que le back
  // n'est pas déployé partout. Le comportement doit être EXACTEMENT celui
  // d'avant ce lot : c'est ce que garantissent, en plus de ce groupe, les tests
  // de « filtrage par permission » restés inchangés (holder absent ⇒ inconnu).
  group('le plan est l\'autorité de périmètre — régime INCONNU '
      '(ADR-015 F5)', () {
    test(
      'le filtre de permission reprend la main, et forbidden compte',
      () async {
        goOnline();
        final autorise = FakePullHandler(
          'classrooms',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.classroomRead],
        );
        final interdit = FakePullHandler(
          'finance_payments',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.financePaymentRead],
        );
        final coord =
            plannedCoordinator(
                planUnknown(),
                permissions: CurrentPermissions()
                  ..set(const ['classroom.read']),
              )
              ..registerHandler(autorise)
              ..registerHandler(interdit);

        final report = await coord.pullAll();

        expect(autorise.calls, 1);
        expect(interdit.calls, 0);
        expect(report.forbidden, 1);
        // Le compteur du régime valide ne bouge pas : les deux autorités ne se
        // superposent jamais.
        expect(report.outOfPlan, 0);
        expect(report.isDegraded, isTrue);
      },
    );

    // L'aval money-grade est bloqué comme avant : pour l'aval, « l'amont a
    // échoué » et « l'amont n'a pas été tenté faute de droit » se valent — dans
    // les deux cas son miroir local est périmé.
    test('l\'aval money-grade est bloqué comme avant : créances sautées faute '
        'de droit ⇒ paiements jamais tentés', () async {
      goOnline();
      final creances = FakePullHandler(
        'finance_student_charges',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financeChargeRead],
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planUnknown(),
              permissions: CurrentPermissions()
                ..set(const ['finance.payment.read']),
            )
            ..registerHandler(creances)
            ..registerHandler(paiements);

      final report = await coord.pullAll();

      expect(creances.calls, 0);
      expect(report.forbidden, 1);
      expect(paiements.calls, 0);
      expect(report.blocked, 1);
    });

    // Le repli ne dépend pas de la RAISON du repli : route absente, réseau,
    // corps illisible, sujet étranger — toutes mènent au même comportement. La
    // cause est une trace de diagnostic, jamais une politique.
    for (final cause in SyncPlanUnknownCause.values) {
      test('cause $cause : même repli, même filtre', () async {
        goOnline();
        final autorise = FakePullHandler(
          'classrooms',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.classroomRead],
        );
        final interdit = FakePullHandler(
          'finance_payments',
          const PullOutcome.updated(),
          requiredPermissions: const [Perm.financePaymentRead],
        );
        final coord =
            plannedCoordinator(
                planUnknown(cause),
                permissions: CurrentPermissions()
                  ..set(const ['classroom.read']),
              )
              ..registerHandler(autorise)
              ..registerHandler(interdit);

        final report = await coord.pullAll();

        expect(autorise.calls, 1);
        expect(interdit.calls, 0);
        expect(report.forbidden, 1);
        expect(report.outOfPlan, 0);
        expect(report.planEmpty, isFalse);
      });
    }

    // Le porteur absent est le montage d'avant ce lot — celui des ~30 tests qui
    // précèdent. Il doit valoir « inconnu », sans quoi le lot serait une
    // régression pour tout appelant non recâblé.
    test('porteur de plan ABSENT ⇒ régime inconnu, à l\'identique', () async {
      goOnline();
      final interdit = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord = PullCoordinator(
        connectivity: service,
        permissions: CurrentPermissions()..set(const ['classroom.read']),
      )..registerHandler(interdit);

      final report = await coord.pullAll();

      expect(interdit.calls, 0);
      expect(report.forbidden, 1);
      expect(report.outOfPlan, 0);
      expect(report.planEmpty, isFalse);
    });
  });

  // ── LE SOCLE, DANS LES TROIS RÉGIMES (ADR-015 M) ──────────────────────────
  //
  // Sans le référentiel, la porte de navigation ne s'ouvre pas et la seule
  // sortie est la déconnexion. Un serveur qui l'omettrait de son plan — ou qui
  // renverrait un plan vide — briquerait le parc. Le socle échappe donc aux
  // TROIS branches du `switch`, et ce n'est pas « écarter » : F-I9 est sauf.
  group('le socle échappe au plan dans les trois régimes', () {
    FakePullHandler socle({bool baseline = true}) => FakePullHandler(
      'enrollment_referential',
      const PullOutcome.updated(upserted: 12),
      requiredPermissions: const [Perm.schoolRead],
      isBaseline: baseline,
    );

    test('régime VALIDE : tiré sous un plan qui ne le contient PAS', () async {
      goOnline();
      final referentiel = socle();
      final coord = plannedCoordinator(
        // Un plan qui omet `school.referential` — le serveur se contredit.
        planKnown(const [SyncPlanKeys.classroomClassrooms]),
        permissions: CurrentPermissions()..set(const []),
      )..registerHandler(referentiel);

      final report = await coord.pullAll();

      expect(referentiel.calls, 1);
      expect(report.updated, 1);
      expect(report.outOfPlan, 0);
      expect(report.forbidden, 0);
    });

    test('régime VIDE : tiré quand même', () async {
      goOnline();
      final referentiel = socle();
      final coord = plannedCoordinator(
        planEmptyState(),
        permissions: CurrentPermissions()..set(const []),
      )..registerHandler(referentiel);

      final report = await coord.pullAll();

      expect(referentiel.calls, 1);
      expect(report.updated, 1);
      // Le plan vide reste signalé — le socle sauvé n'absout pas le contrat
      // rompu.
      expect(report.planEmpty, isTrue);
    });

    test('régime INCONNU : tiré avec des permissions vides', () async {
      goOnline();
      final referentiel = socle();
      final coord = plannedCoordinator(
        planUnknown(),
        permissions: CurrentPermissions()..set(const []),
      )..registerHandler(referentiel);

      final report = await coord.pullAll();

      expect(referentiel.calls, 1);
      expect(report.updated, 1);
      expect(report.forbidden, 0);
    });

    // Contre-épreuve indispensable : sans elle, les trois tests ci-dessus
    // resteraient verts si le `switch` de périmètre avait disparu ENTIÈREMENT.
    // Le handler est le même à un seul champ près.
    test('contre-épreuve : le MÊME handler sans isBaseline est écarté dans les '
        'trois régimes', () async {
      goOnline();
      final permissions = CurrentPermissions()..set(const []);

      final valide = socle(baseline: false);
      final sousPlanValide = plannedCoordinator(
        planKnown(const [SyncPlanKeys.classroomClassrooms]),
        permissions: permissions,
      )..registerHandler(valide);
      final rapportValide = await sousPlanValide.pullAll();

      final vide = socle(baseline: false);
      final sousPlanVide = plannedCoordinator(
        planEmptyState(),
        permissions: permissions,
      )..registerHandler(vide);
      final rapportVide = await sousPlanVide.pullAll();

      final inconnu = socle(baseline: false);
      final sousPlanInconnu = plannedCoordinator(
        planUnknown(),
        permissions: permissions,
      )..registerHandler(inconnu);
      final rapportInconnu = await sousPlanInconnu.pullAll();

      expect(valide.calls, 0);
      expect(rapportValide.outOfPlan, 1);
      expect(vide.calls, 0);
      expect(rapportVide.planEmpty, isTrue);
      expect(inconnu.calls, 0);
      expect(rapportInconnu.forbidden, 1);
    });
  });

  // Le plan gouverne le chemin des écrans exactement comme le cycle complet :
  // les deux partagent le même corps de cycle, et la différence entre eux est
  // le périmètre, jamais la politique.
  group('le plan gouverne pullSubset aussi (ADR-015 F5 × F6)', () {
    test('un écran qui demande une ressource HORS PLAN ne la tire pas, et son '
        'rapport porte outOfPlan', () async {
      goOnline();
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planKnown(const [SyncPlanKeys.classroomClassrooms]),
              permissions: CurrentPermissions()
                ..set(const ['classroom.read', 'finance.payment.read']),
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            ..registerHandler(paiements);

      final report = await coord.pullSubset(const {'finance_payments'});

      expect(paiements.calls, 0);
      expect(report.outOfPlan, 1);
      expect(report.processed, 0);
      expect(report.outcomes, isEmpty);
      // Toujours pas une dégradation : c'est le périmètre du profil.
      expect(report.isDegraded, isFalse);
    });

    test('un écran mixte : la ressource au plan descend, l\'autre est '
        'écartée', () async {
      goOnline();
      final classes = FakePullHandler(
        'classrooms',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.classroomRead],
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planKnown(const [SyncPlanKeys.classroomClassrooms]),
              permissions: CurrentPermissions()
                ..set(const ['classroom.read', 'finance.payment.read']),
            )
            ..registerHandler(classes)
            ..registerHandler(paiements);

      final report = await coord.pullSubset(const {
        'classrooms',
        'finance_payments',
      });

      expect(classes.calls, 1);
      expect(paiements.calls, 0);
      expect(report.updated, 1);
      expect(report.outOfPlan, 1);
      expect(report.outcomes.keys, ['classrooms']);
    });
  });

  // Le plan est résolu APRÈS les deux gardes, et une seule fois par cycle. Le
  // lire avant imposerait un aller-retour — ou son timeout — à chaque montage
  // d'écran hors connexion, et un 401 sur `/sync/plan` se lirait comme une
  // anomalie de déploiement là où il n'y a qu'une session sans jetons.
  group('résolution du plan : où, et combien de fois', () {
    test('hors ligne : le plan n\'est même pas lu', () async {
      goOffline();
      final repo = FakeSyncPlanRepository(
        planKnown(const [SyncPlanKeys.classroomClassrooms]),
      );
      final coord =
          plannedCoordinator(
            planUnknown(),
            repository: repo,
            permissions: CurrentPermissions()..set(const ['classroom.read']),
          )..registerHandler(
            FakePullHandler(
              'classrooms',
              const PullOutcome.updated(),
              requiredPermissions: const [Perm.classroomRead],
            ),
          );

      final report = await coord.pullAll();

      expect(report.offline, isTrue);
      expect(repo.refreshCalls, 0);
      expect(repo.cachedCalls, 0);
    });

    test('sans jetons utilisables : le plan n\'est pas lu non plus', () async {
      goOnline();
      final repo = FakeSyncPlanRepository(
        planKnown(const [SyncPlanKeys.classroomClassrooms]),
      );
      final coord =
          plannedCoordinator(
            planUnknown(),
            repository: repo,
            credentialsProbe: FakeCredentialsProbe.answering(false),
            permissions: CurrentPermissions()..set(const ['classroom.read']),
          )..registerHandler(
            FakePullHandler(
              'classrooms',
              const PullOutcome.updated(),
              requiredPermissions: const [Perm.classroomRead],
            ),
          );

      final report = await coord.pullAll();

      expect(report.skipped, isTrue);
      expect(repo.refreshCalls, 0);
    });

    // Le plan n'a délibérément pas d'ETag : chaque lecture est un corps plein.
    // Un cycle de dix-neuf ressources doit en faire UNE, et le cycle suivant
    // aucune tant que rien n'a changé — sans quoi une navigation normale
    // produirait une dizaine de `GET /sync/plan` par minute.
    test('un seul appel réseau par cycle, et zéro au cycle suivant', () async {
      goOnline();
      final repo = FakeSyncPlanRepository(
        planKnown(const [
          SyncPlanKeys.classroomClassrooms,
          SyncPlanKeys.classroomMembers,
        ]),
      );
      final coord =
          plannedCoordinator(
              planUnknown(),
              repository: repo,
              permissions: CurrentPermissions()..set(const ['classroom.read']),
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            ..registerHandler(
              FakePullHandler(
                'classroom_members',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            );

      await coord.pullAll();
      expect(repo.refreshCalls, 1);

      await coord.pullAll();
      expect(repo.refreshCalls, 1);
    });

    // ADR-015 F9 — sans quoi ce lot introduirait une régression : un droit
    // élargi n'aurait plus d'effet avant le login suivant, alors qu'il est
    // immédiat aujourd'hui. Le porteur s'abonne aux permissions ; un ensemble
    // qui CHANGE marque le plan à relire, et le cycle suivant applique le
    // nouveau périmètre.
    test('F9 : un changement de permissions en séance fait relire le plan, et '
        'le nouveau périmètre s\'applique au cycle suivant', () async {
      goOnline();
      final permissions = CurrentPermissions()..set(const ['classroom.read']);
      // Le plan que le serveur rendra à la RELECTURE : il porte les paiements.
      final repo = FakeSyncPlanRepository(
        planKnown(const [
          SyncPlanKeys.classroomClassrooms,
          SyncPlanKeys.financePayments,
        ]),
      );
      final paiements = FakePullHandler(
        'finance_payments',
        const PullOutcome.updated(),
        requiredPermissions: const [Perm.financePaymentRead],
      );
      final coord =
          plannedCoordinator(
              planUnknown(),
              repository: repo,
              permissions: permissions,
            )
            ..registerHandler(
              FakePullHandler(
                'classrooms',
                const PullOutcome.updated(),
                requiredPermissions: const [Perm.classroomRead],
              ),
            )
            ..registerHandler(paiements);

      await coord.pullAll();
      expect(repo.refreshCalls, 1);

      // Le refresh élargit les droits — sans nouveau login.
      permissions.set(const ['classroom.read', 'finance.payment.read']);

      await coord.pullAll();

      expect(repo.refreshCalls, 2);
      expect(paiements.calls, 2);
    });

    // Le pendant du précédent : un ensemble RÉÉMIS à l'identique (ordre
    // différent compris) ne relit rien. Sous F5, un plan perpétuellement « à
    // relire » restreint le pull au lieu de simplement être en retard.
    test('un ensemble réémis à l\'identique, dans un autre ordre, ne fait pas '
        'relire le plan', () async {
      goOnline();
      final permissions = CurrentPermissions()
        ..set(const ['classroom.read', 'finance.payment.read']);
      final repo = FakeSyncPlanRepository(
        planKnown(const [SyncPlanKeys.classroomClassrooms]),
      );
      final coord =
          plannedCoordinator(
            planUnknown(),
            repository: repo,
            permissions: permissions,
          )..registerHandler(
            FakePullHandler(
              'classrooms',
              const PullOutcome.updated(),
              requiredPermissions: const [Perm.classroomRead],
            ),
          );

      await coord.pullAll();
      expect(repo.refreshCalls, 1);

      permissions.set(const ['finance.payment.read', 'classroom.read']);
      await coord.pullAll();

      expect(repo.refreshCalls, 1);
    });
  });
}

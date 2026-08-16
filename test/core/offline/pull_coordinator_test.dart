import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';

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
class ThrowingPullHandler implements PullHandler {
  @override
  String get resource => 'boom';

  @override
  List<Perm> get requiredPermissions => const [Perm.schoolRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async => throw StateError('réseau coupé');
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
}

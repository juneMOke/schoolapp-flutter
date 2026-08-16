import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';

class _FakeConnectivity implements ConnectivityService {
  final bool online;
  const _FakeConnectivity(this.online);

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

class _StubHandler implements PullHandler {
  @override
  final String resource;
  final PullOutcome outcome;

  @override
  List<Perm> get requiredPermissions => const [Perm.schoolRead];

  @override
  bool get isBaseline => false;

  const _StubHandler(this.resource, this.outcome);

  @override
  Future<PullOutcome> pull() async => outcome;
}

class _ThrowingHandler implements PullHandler {
  @override
  final String resource;

  @override
  List<Perm> get requiredPermissions => const [Perm.schoolRead];

  @override
  bool get isBaseline => false;

  const _ThrowingHandler(this.resource);

  @override
  Future<PullOutcome> pull() async => throw StateError('boom');
}

/// Un abonné qui filtre **exactement** comme les `FeatureScope` réels.
///
/// `CoursesFeatureScope` et `ScheduleFeatureScope` tiennent chacun un
/// `static const Set<String> _watched` et rejettent l'événement sur
/// `resources.intersection(_watched).isEmpty`. Reproduire cette ligne-là, plutôt
/// que « l'ensemble contient-il le nom du handler », est tout l'intérêt : c'est
/// la seule mécanique par laquelle le fan-out se traduit en écran rafraîchi.
class _WatchingScope {
  final Set<String> watched;
  final List<Set<String>> wakeUps = [];
  StreamSubscription<Set<String>>? _sub;

  _WatchingScope(this.watched, PullCompletionBus bus) {
    _sub = bus.stream.listen((resources) {
      if (resources.intersection(watched).isEmpty) return;
      wakeUps.add(resources);
    });
  }

  Future<void> cancel() async => _sub?.cancel();
}

void main() {
  group('PullCompletionBus', () {
    test('ne diffuse rien quand aucune ressource n\'a bougé', () async {
      final bus = PullCompletionBus();
      final seen = <Set<String>>[];
      final sub = bus.stream.listen(seen.add);

      bus.notifyUpdated(const {});
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty);
      await sub.cancel();
      await bus.dispose();
    });

    test('un bus fermé absorbe la notification sans lever — un pull réussi ne '
        'doit jamais échouer à cause du réveil de l\'UI', () async {
      final bus = PullCompletionBus();
      await bus.dispose();

      expect(
        () => bus.notifyUpdated(const {'schedule_sessions'}),
        returnsNormally,
      );
    });

    test('diffuse en broadcast : plusieurs écrans montés reçoivent le même '
        'cycle', () async {
      final bus = PullCompletionBus();
      final a = <Set<String>>[];
      final b = <Set<String>>[];
      final subA = bus.stream.listen(a.add);
      final subB = bus.stream.listen(b.add);

      bus.notifyUpdated(const {'academics_cours'});
      await Future<void>.delayed(Duration.zero);

      expect(a, [
        {'academics_cours'},
      ]);
      expect(b, [
        {'academics_cours'},
      ]);
      await subA.cancel();
      await subB.cancel();
      await bus.dispose();
    });
  });

  group('PullCoordinator → bus', () {
    test('diffuse chaque ressource DÈS qu\'elle est appliquée, et seulement '
        'celles-là (un 304 ou un échec ne réveille personne)', () async {
      final bus = PullCompletionBus();
      final seen = <Set<String>>[];
      final sub = bus.stream.listen(seen.add);

      final coordinator =
          PullCoordinator(
              connectivity: const _FakeConnectivity(true),
              completionBus: bus,
            )
            ..registerHandler(
              const _StubHandler(
                'schedule_sessions',
                PullOutcome.updated(upserted: 3),
              ),
            )
            ..registerHandler(
              const _StubHandler(
                'schedule_time_slots',
                PullOutcome.notModified(),
              ),
            )
            ..registerHandler(const _ThrowingHandler('academics_cours'))
            ..registerHandler(
              const _StubHandler(
                'academics_grades_referential',
                PullOutcome.updated(upserted: 7),
              ),
            );

      final report = await coordinator.pullAll();
      await Future<void>.delayed(Duration.zero); // livraison broadcast

      expect(report.updated, 2);
      expect(report.notModified, 1);
      expect(report.failed, 1);
      // Un événement PAR ressource appliquée, dans l'ordre de leur cycle : un
      // écran n'attend jamais la fin des ressources qui ne le concernent pas.
      expect(seen, [
        {'schedule_sessions'},
        {'academics_grades_referential'},
      ]);

      await sub.cancel();
      await bus.dispose();
    });

    test('hors-ligne : aucun cycle, donc aucune diffusion', () async {
      final bus = PullCompletionBus();
      final seen = <Set<String>>[];
      final sub = bus.stream.listen(seen.add);

      final coordinator =
          PullCoordinator(
            connectivity: const _FakeConnectivity(false),
            completionBus: bus,
          )..registerHandler(
            const _StubHandler(
              'schedule_sessions',
              PullOutcome.updated(upserted: 1),
            ),
          );

      expect((await coordinator.pullAll()).offline, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty);

      await sub.cancel();
      await bus.dispose();
    });
  });

  // ── Le sujet diffusé est la CLÉ DE PLAN, pas le seul nom du handler ────────
  //
  // Deux flux du contrat partagent une clé — l'hydratant d'Inscription
  // (`enrollment_snapshots`) et son delta (`enrollments`) — et ils écrivent les
  // mêmes tables. Diffuser le seul `handler.resource` laisserait un écran
  // abonné à l'autre nom sur un cache froid après un pull qui a pourtant rempli
  // sa table.
  //
  // ⚠️ Aucun écran n'est dans ce cas aujourd'hui : les deux seuls abonnés du bus
  // surveillent academics et schedule. Ces tests ne réparent donc pas une panne
  // observable — ils verrouillent un **contrat de diffusion** avant que le
  // premier écran Inscription ne s'y abonne et n'hérite d'une enquête.
  group('PullCoordinator → bus : le sujet diffusé suit la clé de plan', () {
    /// Monte un coordinateur en ligne avec ces handlers, tire un cycle, et rend
    /// les événements réellement livrés sur le bus.
    Future<List<Set<String>>> broadcastsOf(List<PullHandler> handlers) async {
      final bus = PullCompletionBus();
      final seen = <Set<String>>[];
      final sub = bus.stream.listen(seen.add);

      final coordinator = PullCoordinator(
        connectivity: const _FakeConnectivity(true),
        completionBus: bus,
      );
      for (final handler in handlers) {
        coordinator.registerHandler(handler);
      }

      await coordinator.pullAll();
      await Future<void>.delayed(Duration.zero); // livraison broadcast

      await sub.cancel();
      await bus.dispose();
      return seen;
    }

    test("l'hydratant d'Inscription réveille aussi les abonnés du delta : "
        '{enrollment_snapshots, enrollments}', () async {
      final seen = await broadcastsOf(const [
        _StubHandler('enrollment_snapshots', PullOutcome.updated(upserted: 42)),
      ]);

      expect(seen, hasLength(1));
      expect(seen.single, {'enrollment_snapshots', 'enrollments'});
      // Et c'est bien la table d'alias qui le décide, pas une paire recopiée
      // ici : le jour où la clé porterait une troisième ressource, ce test
      // suivrait au lieu de figer la paire d'aujourd'hui.
      expect(
        seen.single,
        resourcesOf(SyncPlanKeys.enrollmentSnapshots).toSet(),
      );
    });

    test("le delta réveille symétriquement les abonnés de l'hydratant : la "
        'relation est portée par la clé, pas par le sens de lecture', () async {
      final seen = await broadcastsOf(const [
        _StubHandler('enrollments', PullOutcome.updated(upserted: 7)),
      ]);

      expect(seen, hasLength(1));
      expect(seen.single, {'enrollment_snapshots', 'enrollments'});
    });

    test("une clé qui ne porte qu'une ressource ne diffuse que celle-là — le "
        'fan-out ne réveille pas tout le monde', () async {
      // Sans ce test, une diffusion qui enverrait l'univers entier à chaque
      // cycle passerait pour un correctif : chaque écran se rafraîchirait sur
      // le pull d'un domaine qui ne le concerne pas.
      expect(resourcesOf(SyncPlanKeys.classroomClassrooms), ['classrooms']);
      expect(resourcesOf(SyncPlanKeys.financePayments), ['finance_payments']);

      final seen = await broadcastsOf(const [
        _StubHandler('classrooms', PullOutcome.updated(upserted: 3)),
        _StubHandler('finance_payments', PullOutcome.updated(upserted: 5)),
      ]);

      expect(seen, [
        {'classrooms'},
        {'finance_payments'},
      ]);
    });

    test('une ressource inconnue de la table reste diffusée seule : un handler '
        'neuf réveille ses écrans au lieu de devenir muet', () async {
      const neuve = 'flux_pas_encore_inscrit_a_la_table';
      // Précondition : le jour où quelqu'un inscrirait ce nom à la table, le
      // test perdrait son objet — mieux vaut qu'il le dise.
      expect(
        planKeyOf(neuve),
        isNull,
        reason: '« $neuve » doit rester hors de kSyncPlanAliases',
      );

      final seen = await broadcastsOf(const [
        _StubHandler(neuve, PullOutcome.updated(upserted: 1)),
      ]);

      expect(seen, [
        {neuve},
      ]);
    });

    test(
      'le fan-out a élargi le CONTENU de la diffusion, jamais sa condition : '
      "un 304 ou un échec sur la paire d'Inscription ne diffuse rien",
      () async {
        final seen = await broadcastsOf(const [
          _StubHandler('enrollment_snapshots', PullOutcome.notModified()),
          _ThrowingHandler('enrollments'),
        ]);

        expect(seen, isEmpty);
      },
    );

    test(
      "un abonné qui filtre par intersection est réveillé par le nom qu'il "
      "surveille, même quand c'est l'autre handler de la clé qui a tiré",
      () async {
        final bus = PullCompletionBus();
        // Un futur écran Inscription abonné au nom de l'hydratant…
        final inscription = _WatchingScope(const {'enrollment_snapshots'}, bus);
        // …et un témoin d'un tout autre domaine, qui ne doit rien voir.
        final academics = _WatchingScope(const {'academics_cours'}, bus);

        final coordinator =
            PullCoordinator(
              connectivity: const _FakeConnectivity(true),
              completionBus: bus,
            )..registerHandler(
              // C'est le DELTA qui tire, pas l'hydratant surveillé.
              const _StubHandler(
                'enrollments',
                PullOutcome.updated(upserted: 9),
              ),
            );

        await coordinator.pullAll();
        await Future<void>.delayed(Duration.zero);

        expect(
          inscription.wakeUps,
          hasLength(1),
          reason:
              "l'écran lit une table que ce pull vient de remplir : le laisser "
              'sur son cache froid est exactement la trappe qu\'on referme',
        );
        expect(academics.wakeUps, isEmpty);

        await inscription.cancel();
        await academics.cancel();
        await bus.dispose();
      },
    );
  });
}

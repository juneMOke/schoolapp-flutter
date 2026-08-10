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
  });

  @override
  final String resource;

  @override
  final List<Perm> requiredPermissions;
  final PullOutcome _outcome;
  int calls = 0;

  @override
  Future<PullOutcome> pull() async {
    calls++;
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
  });
}

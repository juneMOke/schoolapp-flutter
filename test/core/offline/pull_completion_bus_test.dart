import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
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

  const _StubHandler(this.resource, this.outcome);

  @override
  Future<PullOutcome> pull() async => outcome;
}

class _ThrowingHandler implements PullHandler {
  @override
  final String resource;

  const _ThrowingHandler(this.resource);

  @override
  Future<PullOutcome> pull() async => throw StateError('boom');
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

class _MockEngine extends Mock implements SyncEngine {}

void main() {
  late PullCompletionBus bus;
  late _MockEngine engine;
  late ResourceSyncSignals signals;
  late int removed;

  setUp(() {
    bus = PullCompletionBus();
    engine = _MockEngine();
    removed = 0;
    when(
      () => engine.addFlushCompleteListener(any()),
    ).thenReturn(() => removed++);
    signals = ResourceSyncSignals(
      bus: bus,
      engine: engine,
      watched: const {'a'},
      pull: () async {},
    );
  });

  test('un pull d\'un flux lu signale ; un autre flux non', () async {
    var calls = 0;
    final unwatch = signals.watch(() => calls++);
    bus.notifyUpdated(const {'b'});
    bus.notifyUpdated(const {'a'});
    await pumpEventQueue();

    expect(calls, 1);
    unwatch();
    expect(removed, 1);
  });

  test('onFlush: false — une lecture en ligne ne suit pas les flush', () {
    final unwatch = signals.watch(() {}, onFlush: false);
    verifyNever(() => engine.addFlushCompleteListener(any()));
    unwatch();
    expect(removed, 0);
  });
}

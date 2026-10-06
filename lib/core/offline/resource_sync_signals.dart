import 'dart:async';

import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

/// Ce qui périme la lecture locale d'un écran : un pull qui a écrit l'un des
/// flux qu'il lit ([watched]), et la fin d'un flush — c'est là qu'un accusé
/// change l'état d'une ligne.
class ResourceSyncSignals {
  final PullCompletionBus _bus;
  final SyncEngine _engine;
  final Future<void> Function() _pull;

  /// Les flux lus par l'écran (noms logiques des handlers de pull).
  final Set<String> watched;

  const ResourceSyncSignals({
    required PullCompletionBus bus,
    required SyncEngine engine,
    required this.watched,
    required Future<void> Function() pull,
  }) : _bus = bus,
       _engine = engine,
       _pull = pull;

  /// Tire les flux de l'écran.
  Future<void> pull() => _pull();

  /// Appelle [onChanged] à chaque signal ; rend la fonction qui désabonne.
  ///
  /// [onFlush] : `false` pour un écran qui ne lit rien que l'outbox puisse
  /// changer (une lecture en ligne) — chaque flush, de tout module, le
  /// ferait relire pour rien.
  void Function() watch(void Function() onChanged, {bool onFlush = true}) {
    final subscription = _bus.stream
        .where((resources) => resources.any(watched.contains))
        .listen((_) => onChanged());
    final removeFlushListener = onFlush
        ? _engine.addFlushCompleteListener(onChanged)
        : null;
    return () {
      unawaited(subscription.cancel());
      removeFlushListener?.call();
    };
  }
}

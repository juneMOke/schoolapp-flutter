import 'dart:async';

/// Bus de signalement de révocation de session (ADR-010 D-09).
///
/// Le [AuthSessionManager] y publie quand un `userVersion` divergent a provoqué
/// un wipe (après flush, D-11) ; l'`AuthBloc` s'y abonne pour repasser à
/// `unauthenticated`. Découple le point de décision (boucle de synchro) du point
/// d'affichage (bloc), sans référence croisée directe.
class SessionRevocationBus {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  /// Flux des évènements de révocation.
  Stream<void> get stream => _controller.stream;

  /// Signale une révocation (session déjà wipée par le manager).
  void notifyRevoked() {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}

import 'dart:async';

/// Ce que le battement déclenche. Rendu par l'appelant, jamais connu d'ici.
typedef HeartbeatTick = Future<void> Function();

/// **Cadence** du battement de synchronisation : possède le timer et les deux
/// conditions d'armement, et rien d'autre.
///
/// Séparé de `SyncStatusCubit` parce que ce sont deux responsabilités qui se
/// vérifient différemment : ce qu'un tic *fait* se teste en l'appelant, quand
/// il *part* se teste en manipulant le temps. Mélangées, la seconde n'était
/// testable qu'à coups de `Future.delayed` sur l'horloge murale.
///
/// **Deux conditions indépendantes**, donc réconciliées et non séquencées : une
/// session ouverte (sinon chaque tic interrogerait la sonde de crédentiels
/// d'une session qui n'en a plus) et l'application au premier plan (un `Timer`
/// Dart n'est pas suspendu tant que l'OS n'a pas gelé le processus).
///
/// [_reconcile] ne touche au timer que si l'état d'armement **change**. C'est
/// une garantie, pas une optimisation : recréer le timer à chaque signal
/// remettrait son compte à rebours à zéro, et une tablette qui reçoit un signal
/// plus souvent que la période ne tiquerait jamais — le battement serait mort
/// en affichant « armé ».
class SyncHeartbeat {
  final Duration _interval;
  final HeartbeatTick _onTick;

  Timer? _timer;
  bool _sessionOpen = false;
  bool _foreground;
  bool _ticking = false;
  bool _disposed = false;

  SyncHeartbeat({
    required Duration interval,
    required HeartbeatTick onTick,
    bool foreground = true,
  }) : _interval = interval,
       _onTick = onTick,
       _foreground = foreground;

  /// Vrai si le timer tourne — exposé pour que le câblage se vérifie.
  bool get isActive => _timer != null;

  /// Vrai si un tic est en cours. Un tic peut durer plus longtemps que la
  /// période (un cycle complet sur la connexion d'une école le dépasse
  /// couramment), et deux tics superposés flusheraient la même file deux fois.
  bool get isTicking => _ticking;

  void sessionOpened() {
    _sessionOpen = true;
    _reconcile();
  }

  void sessionClosed() {
    _sessionOpen = false;
    _reconcile();
  }

  void enterForeground() {
    _foreground = true;
    _reconcile();
  }

  void leaveForeground() {
    _foreground = false;
    _reconcile();
  }

  /// Arrête définitivement. Un tic déjà en vol n'est pas interrompu — il n'y a
  /// pas de mécanisme d'annulation coopératif jusqu'au réseau — mais [isActive]
  /// passe à `false` immédiatement, ce que le corps du tic peut relire entre
  /// deux étapes pour renoncer à la suivante.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Un tic, verrou de réentrance compris. Ne lève jamais : personne n'attrape
  /// ce qu'un `Timer` laisse échapper.
  Future<void> tick() async {
    if (_ticking || _disposed) return;
    _ticking = true;
    try {
      await _onTick();
    } catch (_) {
      // Le tic suivant retentera.
    } finally {
      _ticking = false;
    }
  }

  void _reconcile() {
    final shouldBeat = _sessionOpen && _foreground && !_disposed;
    if (shouldBeat == isActive) return;
    if (shouldBeat) {
      _timer = Timer.periodic(_interval, (_) => unawaited(tick()));
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }
}

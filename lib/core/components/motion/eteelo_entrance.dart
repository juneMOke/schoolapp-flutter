import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Entrée en cascade d'un bloc de page : l'enfant monte de [offsetY] en fondu,
/// décalé de [AppMotion.stagger] par rang.
///
/// **L'état final est la base** : sous `MediaQuery.disableAnimations`
/// (reduced-motion), l'enfant est rendu immédiatement à sa place définitive —
/// la page reste simplement visible.
///
/// Le rang est republié aux descendants via [EntranceRank] : un contenu qui
/// s'anime lui-même — un graphique, typiquement — doit attendre son tour
/// plutôt que de se tracer derrière un bloc encore transparent.
class EteeloEntrance extends StatefulWidget {
  /// Rang de l'élément dans la séquence (0 = premier bloc).
  final int index;
  final Widget child;

  /// Durée du fondu-montée (défaut : [AppMotion.entrance]).
  final Duration duration;

  /// Hauteur dont l'enfant monte pendant le fondu.
  final double offsetY;

  const EteeloEntrance({
    super.key,
    required this.index,
    required this.child,
    this.duration = AppMotion.entrance,
    this.offsetY = defaultOffsetY,
  });

  /// Montée par défaut, en dp.
  static const double defaultOffsetY = 12;

  @override
  State<EteeloEntrance> createState() => _EteeloEntranceState();
}

class _EteeloEntranceState extends State<EteeloEntrance> {
  bool _visible = false;
  bool _scheduled = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _visible = true;
      return;
    }
    _timer = Timer(AppMotion.stagger * widget.index, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EntranceRank(
    index: widget.index,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _visible ? 1 : 0),
      duration: widget.duration,
      curve: AppMotion.outCurve,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - progress)),
          child: child,
        ),
      ),
      child: widget.child,
    ),
  );
}

/// Rang d'entrée du bloc englobant, publié par [EteeloEntrance].
class EntranceRank extends InheritedWidget {
  final int index;

  const EntranceRank({super.key, required this.index, required super.child});

  /// Rang du bloc englobant — `0` hors de toute cascade.
  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntranceRank>()?.index ?? 0;

  @override
  bool updateShouldNotify(EntranceRank oldWidget) => oldWidget.index != index;
}

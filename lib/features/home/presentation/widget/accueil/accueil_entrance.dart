import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';

/// Micro-animation d'entrée de la page d'accueil (spec §02).
///
/// L'enfant monte de 12 dp en fondu, avec un décalage de 60 ms par rang.
/// **L'état final est la base** : si les animations sont désactivées
/// (`MediaQuery.disableAnimations` / `prefers-reduced-motion`), l'enfant est
/// affiché immédiatement, à sa place définitive — la page reste simplement
/// visible.
class AccueilEntrance extends StatefulWidget {
  /// Rang de l'élément dans la séquence (0 = bandeau, puis une carte par rang).
  final int index;
  final Widget child;

  const AccueilEntrance({super.key, required this.index, required this.child});

  @override
  State<AccueilEntrance> createState() => _AccueilEntranceState();
}

class _AccueilEntranceState extends State<AccueilEntrance> {
  bool _visible = false;
  Timer? _timer;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _visible = true;
      return;
    }
    _timer = Timer(AccueilUiTokens.entranceStagger * widget.index, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _visible ? 1 : 0),
      duration: AccueilUiTokens.entranceDuration,
      curve: AppMotion.outCurve,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, AccueilUiTokens.entranceOffsetY * (1 - progress)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

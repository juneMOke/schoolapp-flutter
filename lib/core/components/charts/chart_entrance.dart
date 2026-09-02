import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Paramètres d'animation d'un graphique fl_chart, pour la frame courante.
class ChartMotion {
  /// Progression continue de l'entrée, de `0` à `1`.
  final double progress;

  /// À confier au `duration:` du chart : **nulle pendant l'entrée**, que
  /// [ChartEntrance] mène frame par frame — laisser fl_chart interpoler en
  /// plus le ferait courir derrière le tracé. Une fois posé, la main lui est
  /// rendue pour qu'il interpole les changements de données suivants.
  final Duration duration;

  /// À confier au `curve:` du chart.
  final Curve curve;

  const ChartMotion({
    required this.progress,
    required this.duration,
    required this.curve,
  });

  /// [value] ramenée à la progression courante, depuis zéro : une barre pousse
  /// depuis la base, une part d'anneau depuis rien.
  double lerpValue(double value) => value * progress;
}

/// Donne à un graphique fl_chart l'animation d'entrée qu'il n'a pas.
///
/// Les charts de fl_chart sont des `ImplicitlyAnimatedWidget` : ils
/// interpolent seuls d'un jeu de données au suivant, mais jamais au premier
/// build — leur tween y naît avec `begin == end`. [ChartEntrance] mène donc
/// lui-même la progression, de zéro à un : les barres poussent depuis la base,
/// l'anneau se déroule, la courbe se trace de gauche à droite. L'entrée finie,
/// fl_chart reprend la main sur les changements de données.
///
/// Le tracé attend son rang dans la cascade ([EntranceRank], publié par
/// [EteeloEntrance]) : se dessiner derrière une carte encore transparente
/// reviendrait à ne rien montrer.
///
/// En reduced-motion ([MediaQueryData.disableAnimations]) l'état final est
/// rendu dès la première frame et les transitions de données sont instantanées.
class ChartEntrance extends StatefulWidget {
  /// Construit le chart pour la frame courante. La progression s'applique aux
  /// VALEURS confiées à fl_chart, jamais aux bornes du domaine : celles-ci
  /// restent calculées sur les données réelles, sans quoi le tracé garderait
  /// son amplitude et rien ne bougerait.
  final Widget Function(BuildContext context, ChartMotion motion) builder;

  const ChartEntrance({super.key, required this.builder});

  @override
  State<ChartEntrance> createState() => _ChartEntranceState();
}

class _ChartEntranceState extends State<ChartEntrance> {
  bool _started = false;
  bool _settled = false;
  bool _scheduled = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    if (_reduceMotion) {
      _started = true;
      return;
    }
    _timer = Timer(AppMotion.stagger * EntranceRank.of(context), () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = _reduceMotion;
    return TweenAnimationBuilder<double>(
      // En reduced-motion l'entrée n'a pas lieu : partir de zéro la jouerait
      // en durée nulle, donc en un seul coup — et [onEnd] tomberait au milieu
      // du premier build.
      tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: _started ? 1 : 0),
      duration: reduceMotion ? Duration.zero : AppMotion.entrance,
      curve: AppMotion.outCurve,
      onEnd: () {
        if (mounted && !_settled) setState(() => _settled = true);
      },
      builder: (context, progress, _) => widget.builder(
        context,
        ChartMotion(
          progress: progress,
          duration: _settled && !reduceMotion
              ? AppMotion.entrance
              : Duration.zero,
          curve: AppMotion.outCurve,
        ),
      ),
    );
  }
}

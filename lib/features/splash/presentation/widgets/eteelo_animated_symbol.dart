import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Symbole animé du splash (spec COMPOSANT 01). Géométrie reprise telle quelle
/// de `symbole_couleur.svg` (viewBox 200) : disque Blanc Cassé (r 72), « E » en
/// Bleu Profond (effet « gravé », même teinte que le fond) et arc Or Doux
/// (épaisseur 14, linecap rond).
///
/// Animation :
/// - Révélation : le disque + le « E » apparaissent (scale 0.8→1 + fondu),
///   puis l'arc se trace. Piloté par [reveal] (0→1) fourni par la page.
/// - Chargement : l'arc tourne en continu (1,4 s/tour).
/// - Reduced-motion : pas de rotation, symbole rendu immédiatement à l'état
///   final (la page met alors [reveal] à 1).
class EteeloAnimatedSymbol extends StatefulWidget {
  const EteeloAnimatedSymbol({
    super.key,
    required this.diameter,
    required this.reveal,
    required this.semanticsLabel,
    this.spinning = true,
  });

  /// Diamètre du symbole en dp.
  final double diameter;

  /// Progression de la révélation (0→1), pilotée par la page.
  final Animation<double> reveal;

  /// Libellé d'accessibilité (porté par le symbole seul ; le wordmark est
  /// décoratif).
  final String semanticsLabel;

  /// `true` tant que le bootstrap charge : l'arc tourne. `false` fige l'arc.
  final bool spinning;

  /// Durée d'un tour complet de l'arc (spec : 1,4 s/tour).
  static const Duration _spinPeriod = Duration(milliseconds: 1400);

  @override
  State<EteeloAnimatedSymbol> createState() => _EteeloAnimatedSymbolState();
}

class _EteeloAnimatedSymbolState extends State<EteeloAnimatedSymbol>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: EteeloAnimatedSymbol._spinPeriod,
    );
    // L'arc est un indicateur de chargement : sa rotation tourne toujours tant
    // que le bootstrap charge, indépendamment du réglage « réduire les
    // animations » de l'OS (motion fonctionnelle, pas décorative).
    _syncSpin();
  }

  @override
  void didUpdateWidget(EteeloAnimatedSymbol oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spinning != widget.spinning) _syncSpin();
  }

  /// Démarre la rotation pendant le chargement, la fige à l'échec.
  void _syncSpin() {
    if (widget.spinning) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenable = Listenable.merge([widget.reveal, _spin]);
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      child: SizedBox(
        width: widget.diameter,
        height: widget.diameter,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: listenable,
            builder: (context, _) {
              final double r = widget.reveal.value.clamp(0.0, 1.0);
              // Le disque révèle d'abord (60 %), l'arc se trace ensuite (40 %).
              final double discProgress = (r / 0.6).clamp(0.0, 1.0);
              final double arcProgress = ((r - 0.6) / 0.4).clamp(0.0, 1.0);
              final double rotation = _spin.value * 2 * math.pi;
              return CustomPaint(
                painter: _SymbolPainter(
                  discProgress: discProgress,
                  arcProgress: arcProgress,
                  rotation: rotation,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Peintre du symbole. Toutes les coordonnées sont exprimées dans le repère
/// d'origine du SVG (viewBox 200) puis mises à l'échelle par `size`.
class _SymbolPainter extends CustomPainter {
  _SymbolPainter({
    required this.discProgress,
    required this.arcProgress,
    required this.rotation,
  });

  /// Révélation du disque + « E » (scale 0.8→1 + opacité).
  final double discProgress;

  /// Tracé de l'arc (0 → demi-cercle).
  final double arcProgress;

  /// Rotation de l'arc, en radians.
  final double rotation;

  static const double _viewBox = 200;
  static const double _discRadius = 72;
  static const double _arcRadius = 92;
  static const double _arcStroke = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / _viewBox;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // — Disque + « E » : scale 0.8→1 autour du centre + fondu —
    final double discScale = 0.8 + 0.2 * discProgress;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(discScale)
      ..translate(-center.dx, -center.dy);

    canvas.drawCircle(
      center,
      _discRadius * s,
      Paint()..color = AppColors.blancCasse.withValues(alpha: discProgress),
    );

    final ePaint = Paint()
      ..color = AppColors.bleuProfond.withValues(alpha: discProgress);
    _drawLetterE(canvas, s, ePaint);
    canvas.restore();

    // — Arc Or Doux : tracé progressif + rotation —
    if (arcProgress > 0) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(rotation)
        ..translate(-center.dx, -center.dy);

      final arcPaint = Paint()
        ..color = AppColors.orDoux
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arcStroke * s
        ..strokeCap = StrokeCap.round;

      // Demi-cercle droit : départ en haut (-90°), balayage horaire jusqu'en bas.
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: _arcRadius * s),
        -math.pi / 2,
        math.pi * arcProgress,
        false,
        arcPaint,
      );
      canvas.restore();
    }
  }

  /// Dessine le « E » (4 rectangles, repère SVG d'origine).
  void _drawLetterE(Canvas canvas, double s, Paint paint) {
    canvas
      ..drawRect(Rect.fromLTWH(71 * s, 60 * s, 16 * s, 80 * s), paint)
      ..drawRect(Rect.fromLTWH(71 * s, 60 * s, 58 * s, 14 * s), paint)
      ..drawRect(Rect.fromLTWH(71 * s, 93 * s, 44 * s, 14 * s), paint)
      ..drawRect(Rect.fromLTWH(71 * s, 126 * s, 58 * s, 14 * s), paint);
  }

  @override
  bool shouldRepaint(_SymbolPainter old) =>
      old.discProgress != discProgress ||
      old.arcProgress != arcProgress ||
      old.rotation != rotation;
}

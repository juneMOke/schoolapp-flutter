import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// L'anneau du taux perçu : piste voilée, arc or doux, taux au centre.
class RecoveryRateRing extends StatelessWidget {
  final int percent;
  final String label;
  final String? semantics;

  const RecoveryRateRing({
    super.key,
    required this.percent,
    required this.label,
    this.semantics,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final target = (percent / 100).clamp(0.0, 1.0);

    Widget ringAt(double t) => CustomPaint(
      painter: _RingPainter(fraction: target * t),
      child: Center(
        // Le taux ne passe jamais à la ligne : il se réduit dans l'anneau.
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.recoveryRateRingStroke),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.badge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.insInkMain,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: semantics ?? label,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppDimensions.recoveryRateRingSize,
          child: reduceMotion
              ? ringAt(1)
              : TweenAnimationBuilder<double>(
                  key: ValueKey<int>(percent),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppMotion.layout,
                  curve: AppMotion.outCurve,
                  builder: (context, t, _) => ringAt(t),
                ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  /// Voile de la piste (`rgba(255,255,255,.18)` de la maquette).
  static const double _trackVeil = 0.18;

  final double fraction;

  const _RingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppDimensions.recoveryRateRingStroke;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.insInkMain.withValues(alpha: _trackVeil);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (fraction <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = DashboardSense.prestige;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

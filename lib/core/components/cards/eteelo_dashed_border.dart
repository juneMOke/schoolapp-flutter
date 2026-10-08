import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Contour pointillé d'un rectangle arrondi — l'état provisoire ou « en
/// marge » : zone à remplir, élève désactivé, section hors effectif.
class DashedRRectPainter extends CustomPainter {
  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const DashedRRectPainter({
    required this.color,
    this.borderRadius = AppRadius.brCard,
    this.strokeWidth = 1.4,
    this.dash = 8,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()..addRRect(borderRadius.toRRect(rect));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}

/// Une surface au contour pointillé.
class EteeloDashedContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const EteeloDashedContainer({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.borderRadius = AppRadius.brCard,
    this.padding = const EdgeInsets.all(AppDimensions.spacingL),
  });

  @override
  Widget build(BuildContext context) => Material(
    color: backgroundColor,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    borderRadius: borderRadius,
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(
      foregroundPainter: DashedRRectPainter(
        color: borderColor,
        borderRadius: borderRadius,
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

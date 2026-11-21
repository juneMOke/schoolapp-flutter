import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Un trait en tirets pleins (maquette : `repeating-linear-gradient` 5 / 3) :
/// un élément de l'école dans le mois compact et dans la clé de la légende.
class CalendarDashedBar extends StatelessWidget {
  final Color color;
  final double height;

  const CalendarDashedBar({
    super.key,
    required this.color,
    this.height = AppDimensions.calendarBandCompactHeight,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: CustomPaint(painter: _DashesPainter(color)),
  );
}

class _DashesPainter extends CustomPainter {
  final Color color;

  const _DashesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const dash = AppDimensions.calendarBandDash;
    const step = dash + AppDimensions.calendarBandDashGap;
    for (var x = 0.0; x < size.width; x += step) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawRect(Rect.fromLTRB(x, 0, end, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashesPainter old) => old.color != color;
}

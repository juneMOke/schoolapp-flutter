import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Les hachures d'un jour hors du mois (45°).
class CalendarHatchPainter extends CustomPainter {
  const CalendarHatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.calendarOutOfMonthHatch
      ..strokeWidth = AppDimensions.calendarHatchStroke;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    const step = AppDimensions.calendarHatchStep;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CalendarHatchPainter old) => false;
}

/// Le cadre intérieur d'aujourd'hui (terre cuite voilée) ou du jour touché.
class CalendarRingPainter extends CustomPainter {
  final Color color;

  const CalendarRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const w = AppDimensions.calendarSelectedRing;
    canvas.drawRect(
      (Offset.zero & size).deflate(w / 2),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );
  }

  @override
  bool shouldRepaint(CalendarRingPainter old) => old.color != color;
}

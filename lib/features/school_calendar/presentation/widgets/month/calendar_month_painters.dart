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

/// Le dessus d'une semaine du mois, posé PAR-DESSUS les bandes : les traits
/// entre les jours, voilés, et le cadre d'aujourd'hui ([todayCol]) ou du
/// jour touché ([selectedCol]) sur toute la hauteur de la case. Sans lui,
/// une période qui traverse la semaine masquait les deux.
class CalendarWeekOverlayPainter extends CustomPainter {
  final int? todayCol;
  final int? selectedCol;

  const CalendarWeekOverlayPainter({this.todayCol, this.selectedCol});

  @override
  void paint(Canvas canvas, Size size) {
    final col = size.width / 7;
    final line = Paint()
      ..color = AppColors.calendarMonthGridLineOverBand
      ..strokeWidth = 1;
    for (var i = 1; i < 7; i++) {
      final x = (col * i).roundToDouble() + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    void ring(int c, Color color) {
      const w = AppDimensions.calendarSelectedRing;
      canvas.drawRect(
        Rect.fromLTWH(c * col, 0, col, size.height).deflate(w / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w,
      );
    }

    if (todayCol case final c? when c != selectedCol) {
      ring(c, AppColors.calendarTodayRingStrong);
    }
    if (selectedCol case final c?) ring(c, AppColors.bleuArdoise);
  }

  @override
  bool shouldRepaint(CalendarWeekOverlayPainter old) =>
      old.todayCol != todayCol || old.selectedCol != selectedCol;
}

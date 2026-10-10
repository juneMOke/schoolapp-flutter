import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La réglure d'une page de cahier : un filet horizontal tous les 22 dp.
class JournalRulingPainter extends CustomPainter {
  const JournalRulingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.journalRuling
      ..strokeWidth = 1;
    for (
      var y = AppDimensions.journalRuleSpacing;
      y < size.height;
      y += AppDimensions.journalRuleSpacing
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(JournalRulingPainter oldDelegate) => false;
}

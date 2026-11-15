import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Le repère du tracé d'une courbe fl_chart à [count] tranches : l'axe des
/// montants à gauche ([left]), celui des tranches en bas ([bottom]).
double _xOf(Size size, double left, int count, double index) =>
    left + (size.width - left) * (count <= 1 ? 0 : index / (count - 1));

/// Les tranches à venir, hachurées à 45° (spec A4) : elles gardent leur place
/// sur l'axe, sans point.
class TreasuryChartBackdrop extends CustomPainter {
  final int count;
  final int lastKnown;
  final double left;
  final double bottom;

  const TreasuryChartBackdrop({
    required this.count,
    required this.lastKnown,
    required this.left,
    required this.bottom,
  });

  static const double _hatchGap = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (lastKnown >= count - 1) return;
    final start = lastKnown < 0
        ? left
        : _xOf(size, left, count, lastKnown + 0.5);
    final area = Rect.fromLTRB(start, 0, size.width, size.height - bottom);
    canvas
      ..save()
      ..clipRect(area)
      ..drawRect(area, Paint()..color = AppColors.treasuryChartFutureFill);
    final hatch = Paint()
      ..color = AppColors.treasuryChartFutureHatch
      ..strokeWidth = 1.2;
    for (var x = area.left - area.height; x < area.right; x += _hatchGap) {
      canvas.drawLine(
        Offset(x, area.bottom),
        Offset(x + area.height, area.top),
        hatch,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TreasuryChartBackdrop old) =>
      old.count != count ||
      old.lastKnown != lastKnown ||
      old.left != left ||
      old.bottom != bottom;
}

/// L'anneau autour du dernier point connu : il dit « on en est là ».
class TreasuryChartRing extends CustomPainter {
  final int x;
  final double y;
  final int count;
  final double minY;
  final double maxY;
  final double left;
  final double bottom;

  const TreasuryChartRing({
    required this.x,
    required this.y,
    required this.count,
    required this.minY,
    required this.maxY,
    required this.left,
    required this.bottom,
  });

  static const double _radius = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final plotHeight = size.height - bottom;
    final span = maxY - minY == 0 ? 1 : maxY - minY;
    final center = Offset(
      _xOf(size, left, count, x.toDouble()),
      plotHeight * (1 - (y - minY) / span),
    );
    canvas
      ..drawCircle(
        center,
        _radius,
        Paint()..color = AppColors.terreCuite.withValues(alpha: 0.12),
      )
      ..drawCircle(
        center,
        _radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.terreCuite.withValues(alpha: 0.2),
      );
  }

  @override
  bool shouldRepaint(TreasuryChartRing old) =>
      old.x != x || old.y != y || old.minY != minY || old.maxY != maxY;
}

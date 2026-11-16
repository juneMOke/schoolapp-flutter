import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

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

/// L'anneau du dernier point connu (spec A4) : il pulse en 1,8 s, de 6 à
/// 18 de rayon en s'effaçant ; fixe quand les animations sont réduites.
class TreasuryPulsingRing extends StatefulWidget {
  final int x;
  final double y;
  final int count;
  final double maxY;
  final double left;
  final double bottom;

  const TreasuryPulsingRing({
    super.key,
    required this.x,
    required this.y,
    required this.count,
    required this.maxY,
    required this.left,
    required this.bottom,
  });

  @override
  State<TreasuryPulsingRing> createState() => _TreasuryPulsingRingState();
}

class _TreasuryPulsingRingState extends State<TreasuryPulsingRing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _RingPainter(
          x: widget.x,
          y: widget.y,
          count: widget.count,
          maxY: widget.maxY,
          left: widget.left,
          bottom: widget.bottom,
          progress: still ? null : _controller.value,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int x;
  final double y;
  final int count;
  final double maxY;
  final double left;
  final double bottom;

  /// 0 → 1 au fil d'une pulsation ; `null` : anneau fixe.
  final double? progress;

  const _RingPainter({
    required this.x,
    required this.y,
    required this.count,
    required this.maxY,
    required this.left,
    required this.bottom,
    required this.progress,
  });

  static const double _from = 6;
  static const double _to = 18;
  static const double _still = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final plotHeight = size.height - bottom;
    final span = maxY == 0 ? 1 : maxY;
    final center = Offset(
      _xOf(size, left, count, x.toDouble()),
      plotHeight * (1 - y / span),
    );
    final t = progress;
    final radius = t == null ? _still : _from + (_to - _from) * t;
    final alpha = t == null ? 0.16 : 0.35 * (1 - t);
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.terreCuite.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.x != x || old.y != y || old.maxY != maxY;
}

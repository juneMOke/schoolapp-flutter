import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';

/// Les soldes de fin de journée des 8 derniers jours de caisse (A2, R3) :
/// un trait clair, le dernier point en or doux. Purement décoratif — le
/// montant exact est écrit à côté.
class BalanceSparkline extends StatelessWidget {
  final List<DayBalance> days;
  final Size size;

  const BalanceSparkline({super.key, required this.days, required this.size});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: size, painter: _SparklinePainter(days)),
  );
}

class _SparklinePainter extends CustomPainter {
  final List<DayBalance> days;

  const _SparklinePainter(this.days);

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;
    final values = [for (final d in days) d.balanceInCents.toDouble()];
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = max - min == 0 ? 1.0 : max - min;
    const inset = 4.0;
    Offset at(int i) => Offset(
      inset + (size.width - 2 * inset) * i / (values.length - 1),
      inset + (size.height - 2 * inset) * (1 - (values[i] - min) / span),
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = DashboardTones.inkValeur.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      at(values.length - 1),
      3.5,
      Paint()..color = AppColors.orDoux,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.days != days;
}

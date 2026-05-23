import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

class EteeloTechLogo extends StatelessWidget {
  const EteeloTechLogo({super.key});

  static const Color primaryBlue = AppColors.bleuArdoise;
  static const Color secondaryGreen = AppColors.terreCuite;
  static const Color slateBlue = AppColors.bleuProfond;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _TechIcon(),
        const SizedBox(height: 24),
        Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      color: slateBlue,
                      height: 1.0,
                    ),
                    children: [TextSpan(text: 'ETEELO')],
                  ),
                ),
                Positioned(
                  top: -35,
                  left: -25,
                  child: Transform.rotate(
                    angle: -0.7,
                    child: const Icon(
                      Icons.school_rounded,
                      color: primaryBlue,
                      size: 50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: secondaryGreen,
                borderRadius: AppRadius.brSm,
              ),
              child: const Text(
                'CONNECT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8.0,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TechIcon extends StatelessWidget {
  const _TechIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dynamic background
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: EteeloTechLogo.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          // Outer circuit ring (simplified)
          CustomPaint(
            size: const Size(100, 100),
            painter: _CircuitPainter(
              EteeloTechLogo.primaryBlue,
              EteeloTechLogo.secondaryGreen,
            ),
          ),
          // Central icon with modern styling
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: EteeloTechLogo.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.textOnDark,
              size: 28,
            ),
          ),
          // Pulse effect (simulated with nodes)
          for (int i = 0; i < 4; i++) _PositionedNode(index: i),
        ],
      ),
    );
  }
}

class _PositionedNode extends StatelessWidget {
  final int index;
  const _PositionedNode({required this.index});

  @override
  Widget build(BuildContext context) {
    const double radius = 35;

    return Positioned(
      top: 50 + radius * (index < 2 ? -0.7 : 0.7) - 6,
      left: 50 + radius * (index % 3 == 0 ? -0.7 : 0.7) - 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: index % 2 == 0
              ? EteeloTechLogo.primaryBlue
              : EteeloTechLogo.secondaryGreen,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textOnDark, width: 2),
        ),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  _CircuitPainter(this.color1, this.color2);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw connecting lines with gradients
    for (int i = 0; i < 4; i++) {
      paint.color = i % 2 == 0
          ? color1.withValues(alpha: 0.5)
          : color2.withValues(alpha: 0.5);
      final double endX = i < 2 ? size.width * 0.25 : size.width * 0.75;
      final double endY = i % 2 == 0 ? size.height * 0.25 : size.height * 0.75;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(endX, endY);

      canvas.drawPath(path, paint);
    }

    // Draw an outer circle dash-like
    paint.strokeWidth = 1;
    canvas.drawCircle(center, 42, paint..color = color1.withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Point d'état « en cours » avec halo pulsé (spec §12). Respecte
/// `prefers-reduced-motion` : le halo est figé si les animations système sont
/// désactivées (cf. `MediaQuery.disableAnimations`).
class NotationPulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const NotationPulseDot({super.key, required this.color, this.size = 7});

  @override
  State<NotationPulseDot> createState() => _NotationPulseDotState();
}

class _NotationPulseDotState extends State<NotationPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
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
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_controller.isAnimating)
                Opacity(
                  opacity: (1 - t) * 0.45,
                  child: Container(
                    width: widget.size * (1 + t * 1.6),
                    height: widget.size * (1 + t * 1.6),
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
        child: dot,
      ),
    );
  }
}

/// Pastille de statut arrondie (médaillon doux + libellé coloré) — réutilisée
/// par les onglets, la frise, le panneau et les lignes d'évaluation (spec §2–§5).
class NotationPill extends StatelessWidget {
  final Color color;
  final Color soft;
  final String label;
  final IconData? icon;

  /// Remplace l'icône par un point pulsé « en cours ».
  final bool pulseDot;

  const NotationPill({
    super.key,
    required this.color,
    required this.soft,
    required this.label,
    this.icon,
    this.pulseDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulseDot) ...[
            NotationPulseDot(color: color),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

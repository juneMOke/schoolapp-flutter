import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Squelette de la table des frais (PARCOURS 20) : placeholders animés (pulse)
/// mimant désignation + montant par ligne, puis la ligne de total. Respecte
/// reduced-motion (barres statiques si les animations sont désactivées).
class StudentChargesLoadingState extends StatelessWidget {
  const StudentChargesLoadingState({super.key});

  static const int _rowCount = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rowCount; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Expanded(flex: 3, child: _SkeletonBar(height: 14)),
                SizedBox(width: AppSpacing.md),
                Expanded(flex: 1, child: _SkeletonBar(height: 14)),
              ],
            ),
          ),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(flex: 3, child: _SkeletonBar(height: 18)),
            SizedBox(width: AppSpacing.md),
            Expanded(flex: 1, child: _SkeletonBar(height: 18)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBar extends StatefulWidget {
  final double height;

  const _SkeletonBar({required this.height});

  @override
  State<_SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<_SkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return _bar(AppColors.border);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color =
            Color.lerp(
              AppColors.border,
              AppColors.surfaceRaised,
              _controller.value,
            ) ??
            AppColors.border;
        return _bar(color);
      },
    );
  }

  Widget _bar(Color color) => Container(
    height: widget.height,
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.brSm),
  );
}

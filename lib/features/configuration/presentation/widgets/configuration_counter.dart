import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';

/// Compteur ± de l'assistant.
///
/// Les deux boutons mesurent 30 dp à l'œil mais occupent une zone tactile de
/// 44 dp : la cible réelle est plus grande que le dessin, comme partout ailleurs
/// dans l'application.
class ConfigurationCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final Color accentColor;

  /// Grisé sans être masqué : sur un niveau à barèmes, le réglage global du
  /// cycle ne s'applique pas — mais l'utilisateur doit voir ce qui existe.
  final bool enabled;

  final int max;

  const ConfigurationCounter({
    super.key,
    required this.value,
    required this.onChanged,
    this.accentColor = AppColors.terreCuite,
    this.enabled = true,
    this.max = StructureSelection.maxPerColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Step(
          icon: Icons.remove_rounded,
          accentColor: accentColor,
          onPressed: enabled && value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _Step(
          icon: Icons.add_rounded,
          accentColor: accentColor,
          onPressed: enabled && value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _Step({
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;

    return SizedBox(
      // Zone tactile pleine, dessin plus petit à l'intérieur.
      width: AppDimensions.minTouchTarget,
      height: AppDimensions.minTouchTarget,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.brSm,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brSm,
                border: Border.all(
                  color: active
                      ? accentColor.withValues(alpha: 0.55)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: active ? accentColor : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

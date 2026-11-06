import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

class EteeloChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  /// Vrai quand la puce vit sous un parent qui borne sa largeur (un `Wrap`
  /// dans une carte) : un libellé plus long que la rangée — un motif
  /// d'absence, une date en toutes lettres sur un téléphone — passe à la
  /// ligne au lieu de déborder. Faux — le défaut — : la puce garde sa
  /// largeur naturelle, ce qu'exige une puce posée telle quelle dans une
  /// `Row` (qui ne la borne pas : un libellé flexible y lèverait).
  final bool wrapLabel;

  const EteeloChip({
    super.key,
    this.icon,
    required this.label,
    this.wrapLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.chipPaddingH,
        vertical: AppDimensions.chipPaddingV,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppDimensions.chipIconSize,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (wrapLabel) Flexible(child: text) else text,
        ],
      ),
    );
  }
}

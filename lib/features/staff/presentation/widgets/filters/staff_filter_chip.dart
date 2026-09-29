import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une puce de filtre à compteur : pleine de sa couleur quand elle est active.
/// Sans compteur ([count] `null`), c'est une puce de choix — motif d'une
/// justification, tolérance d'un réglage.
class StaffFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final Color color;
  final Color soft;
  final Color ink;
  final IconData? icon;

  /// `null` : la puce se lit sans se toucher (réglages en lecture seule).
  final VoidCallback? onTap;

  const StaffFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.soft,
    required this.ink,
    required this.onTap,
    this.count,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? soft : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brPill,
          side: BorderSide(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.staffFilterChipHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: selected ? ink : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: selected ? ink : AppColors.textPrimary,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$count',
                      style: AppTypography.labelMedium.copyWith(
                        color: selected ? ink : AppColors.textMutedAa,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

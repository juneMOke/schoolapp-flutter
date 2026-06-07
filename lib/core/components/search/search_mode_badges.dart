import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Badges récapitulatifs du mode de recherche armé.
///
/// Coche verte si le groupe correspondant est complet, sinon anneau gris.
class SearchModeBadges extends StatelessWidget {
  final String activeModeLabel;
  final String studentBadgeLabel;
  final String classBadgeLabel;
  final bool studentArmed;
  final bool classArmed;

  const SearchModeBadges({
    super.key,
    required this.activeModeLabel,
    required this.studentBadgeLabel,
    required this.classBadgeLabel,
    required this.studentArmed,
    required this.classArmed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          activeModeLabel,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        _ModeBadge(label: studentBadgeLabel, armed: studentArmed),
        _ModeBadge(label: classBadgeLabel, armed: classArmed),
      ],
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String label;
  final bool armed;

  const _ModeBadge({required this.label, required this.armed});

  @override
  Widget build(BuildContext context) {
    final color = armed ? AppColors.feeStatusPaid : AppColors.textMuted;
    final borderColor = armed
        ? AppColors.feeStatusPaidBorder
        : AppColors.border;
    final fillColor = armed
        ? AppColors.feeStatusPaidSoft
        : AppColors.surfaceAlt;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            armed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(label, style: AppTextStyles.badge.copyWith(color: color)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le bandeau des totaux d'un récapitulatif du mois : des paires libellé ·
/// valeur, ce que la clôture transmettra.
class PresenceTotalsBand extends StatelessWidget {
  final List<(String label, String value)> totals;

  const PresenceTotalsBand({super.key, required this.totals});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.bleuArdoiseSoft,
      borderRadius: AppRadius.brLg,
    ),
    child: Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.md,
      children: [
        for (final (label, value) in totals)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une lecture (`FinInsight`) : carte teintée de son ton, filet gauche,
/// médaillon, titre, phrase, et au besoin une action.
class RecoveryInsightCard extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const RecoveryInsightCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  static const _radius = BorderRadius.all(
    Radius.circular(AppDimensions.recoveryInsightRadius),
  );

  @override
  Widget build(BuildContext context) {
    final ink = DashboardTones.encreLisible(tone);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + AppDimensions.recoveryInsightFilet,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      // Deux couches : un rayon sous une bordure de deux couleurs lève au
      // `paint()`. Le tour teinté dessous, le filet du ton par-dessus.
      decoration: BoxDecoration(
        color: DashboardTones.teinte(tone, 5),
        borderRadius: _radius,
        border: Border.all(color: ColorMix.tint(AppColors.border, tone, 18)),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: _radius,
        border: Border(
          left: BorderSide(
            color: tone,
            width: AppDimensions.recoveryInsightFilet,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: AppDimensions.recouvrementInsightMedallion,
              height: AppDimensions.recouvrementInsightMedallion,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(
                  AppDimensions.recoveryInsightMedallionRadius,
                ),
                border: Border.all(color: tone.withValues(alpha: 0.22)),
              ),
              child: Icon(
                icon,
                size: AppDimensions.recoveryInsightIcon,
                color: ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton.icon(
                    onPressed: onAction,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: AppDimensions.recoverySimChipIcon,
                    ),
                    label: Text(actionLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: ink,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, AppDimensions.minTouchTarget),
                      textStyle: AppTypography.labelLarge,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

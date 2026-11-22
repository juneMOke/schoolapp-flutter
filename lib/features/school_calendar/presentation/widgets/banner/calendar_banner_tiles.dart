import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// « 21 nationaux », « 10 internes » : chiffre en serif, libellé et icône.
class CalendarCountTile extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;

  const CalendarCountTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(
      minWidth: AppDimensions.calendarBannerCountMinWidth,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.calendarBannerTile,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.calendarBannerTileBorder),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: AppTypography.calendarTileValue.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.xs / 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimensions.calendarBannerSmallIcon,
              color: AppColors.calendarBannerTileLabel,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.calendarBannerTileLabel,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Une ligne de texte du bandeau replié : « Période · P4 · 2e semestre ».
class CalendarBannerTextLine extends StatelessWidget {
  final String label;
  final String value;

  const CalendarBannerTextLine({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelMedium.copyWith(
      color: AppColors.textOnDark,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label · ',
            style: style.copyWith(color: AppColors.orDoux),
          ),
          TextSpan(text: value),
        ],
      ),
      style: style,
    );
  }
}

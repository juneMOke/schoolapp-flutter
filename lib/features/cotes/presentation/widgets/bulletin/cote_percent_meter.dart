import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « 61/80 », sa jauge et son pourcentage. Sur téléphone, le total seul.
class CoteTotalValue extends StatelessWidget {
  final String obtained;
  final String max;
  final int? percent;
  final bool showMeter;
  final bool dense;

  const CoteTotalValue({
    super.key,
    required this.obtained,
    required this.max,
    required this.percent,
    this.showMeter = true,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = cotePercentColor(percent);
    final meterWidth = dense
        ? AppDimensions.coteMeterWidthDense
        : AppDimensions.coteMeterWidth;
    final total = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: obtained,
            style: const TextStyle(
              color: AppColors.noirChaud,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '/$max',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      style: AppTypography.bodySmall,
    );
    final shrinking = FittedBox(fit: BoxFit.scaleDown, child: total);
    if (!showMeter) return shrinking;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(child: shrinking),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: meterWidth,
          height: AppDimensions.coteMeterHeight,
          child: ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: (percent ?? 0).clamp(0, 100) / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          percent == null ? '—' : l10n.cotePercent(percent!),
          maxLines: 1,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

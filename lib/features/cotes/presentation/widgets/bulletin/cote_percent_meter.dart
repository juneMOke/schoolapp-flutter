import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « 61/80 », sa jauge et son pourcentage. Sur téléphone, le total seul.
class CoteTotalValue extends StatelessWidget {
  final String obtained;
  final String max;
  final int? percent;

  /// L'encre du score ; `null` si rien n'est rempli.
  final Color? ink;
  final bool showMeter;
  final bool dense;

  const CoteTotalValue({
    super.key,
    required this.obtained,
    required this.max,
    required this.percent,
    required this.ink,
    this.showMeter = true,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = ink ?? AppColors.textMuted;
    final meterWidth = dense
        ? AppDimensions.coteMeterWidthDense
        : AppDimensions.coteMeterWidth;
    final total = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: obtained,
            style: TextStyle(
              color: ink ?? AppColors.noirChaud,
              fontWeight: FontWeight.w700,
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (percent ?? 0).clamp(0, 100) / 100),
              duration: AppMotion.standard,
              curve: AppMotion.outCurve,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
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

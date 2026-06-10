import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceResultsToolbar extends StatelessWidget {
  final int presentCount;
  final int justifiedCount;
  final int unjustifiedCount;
  final int pendingCount;
  final int total;

  const AttendanceResultsToolbar({
    super.key,
    required this.presentCount,
    required this.justifiedCount,
    required this.unjustifiedCount,
    required this.pendingCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingXS,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CountPill(
                count: presentCount,
                label: l10n.attendancePresentCount,
                color: AppColors.success,
              ),
              _CountPill(
                count: justifiedCount,
                label: l10n.attendanceJustifiedCount,
                color: AppColors.warning,
              ),
              _CountPill(
                count: unjustifiedCount,
                label: l10n.attendanceUnjustifiedCount,
                color: AppColors.danger,
              ),
              if (pendingCount > 0)
                _CountPill(
                  count: pendingCount,
                  label: l10n.attendancePendingCount,
                  color: AppColors.warning,
                  isWarning: true,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        _EffectifCounter(total: total),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool isWarning;

  const _CountPill({
    required this.count,
    required this.label,
    required this.color,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWarning)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(Icons.warning_amber_rounded, size: 13, color: color),
            )
          else
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectifCounter extends StatelessWidget {
  final int total;

  const _EffectifCounter({required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$total',
          style: AppTextStyles.totalAmountLora.copyWith(
            fontSize: AppDimensions.attendanceCounterValueFontSize,
            color: AppColors.bleuArdoise,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          l10n.attendanceTotalCount,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

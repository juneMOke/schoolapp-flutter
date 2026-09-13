import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_period_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Navigation de période (spec §2) : deux gestes séparés — la granularité
/// (quelle taille de fenêtre) et le pas à pas (quelle fenêtre). « › » s'arrête
/// à la période en cours ; un lien ramène d'un clic à aujourd'hui.
class ExpensePeriodBar extends StatelessWidget {
  final ExpensePeriod period;
  final ExpenseDateRange range;
  final ValueChanged<ExpenseGranularity> onGranularityChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;

  const ExpensePeriodBar({
    super.key,
    required this.period,
    required this.range,
    required this.onGranularityChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = ExpensePeriodLabel.of(context, period, range);
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedTabFilter<ExpenseGranularity>(
          semanticsLabel: l10n.expensePeriodGranularityA11y,
          selected: period.granularity,
          onSelected: onGranularityChanged,
          options: [
            for (final value in ExpenseGranularity.values)
              SegmentedTabOption(
                label: expenseGranularityLabel(l10n, value),
                value: value,
              ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Arrow(
              icon: Icons.arrow_back,
              tooltip: l10n.expensePeriodPrevious,
              onPressed: onPrevious,
            ),
            SizedBox(
              width: AppDimensions.expensePeriodLabelWidth,
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Text(
                      label.relative,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong,
                    ),
                    Text(
                      label.detail,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Arrow(
              icon: Icons.arrow_forward,
              tooltip: l10n.expensePeriodNext,
              // L'école ne consulte pas ses dépenses futures.
              onPressed: period.canGoForward ? onNext : null,
            ),
          ],
        ),
        if (!period.isCurrent)
          TextButton(
            onPressed: onCurrent,
            child: Text(l10n.expensePeriodBackToCurrent),
          ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _Arrow({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: AppDimensions.expensePeriodArrowIconSize,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppDimensions.expensePeriodArrowSize),
        minimumSize: const Size.square(AppDimensions.expensePeriodArrowSize),
        backgroundColor: AppColors.surfaceRaised,
        foregroundColor: AppColors.bleuArdoise,
        disabledForegroundColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.expensePeriodArrowRadius,
          ),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      icon: Icon(icon, color: enabled ? null : AppColors.textMuted),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/header/journal_nav_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête d'une page du cahier : ◀ date ▶, « Aujourd'hui », le compteur
/// d'avancement et le N° de page. Visible dans tous les états.
class JournalDayHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  /// La page lue ; `null` pendant un chargement ou après un échec.
  final JournalDay? day;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToday;

  const JournalDayHeader({
    super.key,
    required this.date,
    required this.isToday,
    required this.onToday,
    this.day,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            JournalNavButton(
              icon: Icons.chevron_left_rounded,
              tooltip: l10n.journalPreviousDay,
              onPressed: onPrevious,
            ),
            _DateLabel(date: date, isToday: isToday),
            JournalNavButton(
              icon: Icons.chevron_right_rounded,
              tooltip: l10n.journalNextDay,
              onPressed: onNext,
            ),
            if (!isToday)
              EteeloButton.secondary(
                label: l10n.journalToday,
                icon: Icons.calendar_today_rounded,
                onPressed: onToday,
                fullWidth: false,
              ),
          ],
        ),
        if (day case final day?) _Progress(day: day),
      ],
    );
  }
}

class _DateLabel extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  const _DateLabel({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.journalDateEyebrow.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: AppDimensions.journalEyebrowLetterSpacing,
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.journalHeaderDate(date),
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (isToday)
              Text(
                l10n.journalTodayMarker,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  final JournalDay day;

  const _Progress({required this.day});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pageNumber = day.pageNumber;
    return Wrap(
      spacing: AppSpacing.lg,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!day.isEmpty)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l10n.journalCounterValue(
                    day.filledCount,
                    day.lines.length,
                  ),
                  style: AppTypography.labelMedium.copyWith(
                    color: day.isComplete
                        ? AppColors.vertSavane
                        : AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' ${l10n.journalCounterLabel(day.lines.length)}',
                ),
              ],
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        if (pageNumber != null)
          Text(
            l10n.journalPageNumber(pageNumber),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

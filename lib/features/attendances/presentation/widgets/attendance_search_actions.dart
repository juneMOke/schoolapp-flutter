import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceDateButton extends StatelessWidget {
  final DateTime date;
  final Future<void> Function() onPickDate;

  const AttendanceDateButton({
    super.key,
    required this.date,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(date);

    return SizedBox(
      width: AppDimensions.classesOrganisationCompactFieldWidth,
      child: Tooltip(
        message: l10n.attendanceDateTooltip,
        child: OutlinedButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.attendanceDateLabel,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                dateLabel,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppDimensions.minTouchTarget),
            alignment: Alignment.centerLeft,
            backgroundColor: AppColors.background,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
            ),
          ),
        ),
      ),
    );
  }
}

class AttendanceSearchButton extends StatelessWidget {
  final bool isSearching;
  final bool canSearch;
  final VoidCallback onSearch;
  final bool isCompact;

  const AttendanceSearchButton({
    super.key,
    required this.isSearching,
    required this.canSearch,
    required this.onSearch,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: ElevatedButton.icon(
        key: ValueKey('attendance-search-$isSearching-$canSearch-$isCompact'),
        onPressed: canSearch ? onSearch : null,
        icon: isSearching
            ? const SizedBox(
                width: AppDimensions.detailMiniIconSize,
                height: AppDimensions.detailMiniIconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Icon(Icons.search),
        label: Text(l10n.search),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.classesDisabledBg,
          disabledForegroundColor: AppColors.classesDisabledFg,
          minimumSize: Size(isCompact ? 0 : 140, AppDimensions.minTouchTarget),
        ),
      ),
    );
  }
}

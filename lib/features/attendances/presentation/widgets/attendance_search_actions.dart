import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceDateButton extends StatelessWidget {
  final DateTime date;
  final Future<void> Function() onPickDate;
  final double width;

  const AttendanceDateButton({
    super.key,
    required this.date,
    required this.onPickDate,
    this.width = AppDimensions.classesOrganisationCompactFieldWidth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(date);

    return SizedBox(
      width: width,
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
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                dateLabel,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
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

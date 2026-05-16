import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceResultsToolbar extends StatelessWidget {
  final String classroomName;
  final String formattedDate;
  final bool hasUnsavedChanges;
  final int presentCount;
  final int absentCount;
  final int totalCount;

  const AttendanceResultsToolbar({
    super.key,
    required this.classroomName,
    required this.formattedDate,
    required this.hasUnsavedChanges,
    required this.presentCount,
    required this.absentCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroomName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontFamily: 'Lora',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '${l10n.attendanceDateLabel}: $formattedDate · ${hasUnsavedChanges ? l10n.attendanceStatusInProgress : l10n.attendanceStatusReady}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingXS,
              alignment: WrapAlignment.end,
              children: [
                _CounterItem(
                  label: l10n.attendancePresentCount,
                  value: presentCount,
                  color: AppColors.success,
                ),
                _CounterItem(
                  label: l10n.attendanceAbsentCount,
                  value: absentCount,
                  color: AppColors.danger,
                ),
                _CounterItem(
                  label: l10n.attendanceTotalCountCompact,
                  value: totalCount,
                  color: AppColors.bleuProfond,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.financeDetailMutedSurface,
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            l10n.attendanceDefaultPresenceHelper,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CounterItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.attendanceCounterColumnWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTextStyles.totalAmountLora.copyWith(
              fontSize: AppDimensions.attendanceCounterValueFontSize,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

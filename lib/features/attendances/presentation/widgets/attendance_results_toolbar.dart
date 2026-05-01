import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_style_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceResultsToolbar extends StatelessWidget {
  final AttendanceStats stats;
  final int modifiedCount;
  final bool hasUnsavedChanges;
  final bool hasValidationErrors;
  final bool isSaving;
  final VoidCallback onExportPressed;
  final VoidCallback? onSavePressed;

  const AttendanceResultsToolbar({
    super.key,
    required this.stats,
    required this.modifiedCount,
    required this.hasUnsavedChanges,
    required this.hasValidationErrors,
    required this.isSaving,
    required this.onExportPressed,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = [
      _StatChip(
        label: l10n.attendanceTotalCount,
        value: stats.total,
        bg: AppColors.classesChipTotalBg,
        fg: AppColors.classesChipTotalFg,
      ),
      _StatChip(
        label: l10n.attendanceGirlsCount,
        value: stats.girls,
        bg: AppColors.classesChipGirlsBg,
        fg: AppColors.classesChipGirlsFg,
      ),
      _StatChip(
        label: l10n.attendanceBoysCount,
        value: stats.boys,
        bg: AppColors.classesChipBoysBg,
        fg: AppColors.classesChipBoysFg,
      ),
      if (hasUnsavedChanges)
        _StatChip(
          label: hasValidationErrors
              ? l10n.attendancePendingInvalidChanges
              : l10n.attendancePendingChanges,
          value: modifiedCount,
          bg: hasValidationErrors
              ? AppColors.financeDetailDangerSoft
              : AppColors.financeDetailAccentSoft,
          fg: hasValidationErrors ? AppColors.danger : AppColors.financeDetailAccent,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < AppBreakpoints.detailCompactMax;
        final saveButton = FocusTraversalOrder(
          order: const NumericFocusOrder(1),
          child: Tooltip(
            message: hasValidationErrors
                ? l10n.attendanceSaveValidationHint
                : l10n.attendanceSaveTooltip,
            preferBelow: AttendanceStyleTokens.tooltipPreferBelow,
            child: ElevatedButton.icon(
              onPressed: onSavePressed,
              icon: isSaving
                  ? const SizedBox(
                      width: AppDimensions.detailMiniIconSize,
                      height: AppDimensions.detailMiniIconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isSaving ? l10n.attendanceSavingAction : l10n.attendanceSaveAction,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.surface,
                disabledBackgroundColor: AppColors.classesDisabledBg,
                disabledForegroundColor: AppColors.classesDisabledFg,
                minimumSize: AttendanceStyleTokens.saveButtonMinSize,
                textStyle: AppTextStyles.action,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                elevation: hasUnsavedChanges ? AppDimensions.spacingXS : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                ),
                iconSize: AppDimensions.detailHeaderIconSize,
              ),
            ),
          ),
        );
        final exportButton = FocusTraversalOrder(
          order: const NumericFocusOrder(2),
          child: Tooltip(
            message: l10n.attendanceExportTooltip,
            preferBelow: AttendanceStyleTokens.tooltipPreferBelow,
            child: ElevatedButton.icon(
              onPressed: onExportPressed,
              icon: const Icon(Icons.ios_share_outlined),
              label: Text(l10n.attendanceExportAction),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.financeDetailSecondaryAccent,
                foregroundColor: AppColors.surface,
                minimumSize: AttendanceStyleTokens.exportButtonMinSize,
                textStyle: AppTextStyles.action,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                ),
                iconSize: AppDimensions.detailHeaderIconSize,
              ),
            ),
          ),
        );

        return AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.outCurve,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: chips,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              FocusTraversalGroup(
                child: SizedBox(
                  width: isCompact ? double.infinity : null,
                  child: isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            saveButton,
                            const SizedBox(height: AppDimensions.spacingS),
                            exportButton,
                          ],
                        )
                      : Wrap(
                          spacing: AppDimensions.spacingS,
                          runSpacing: AppDimensions.spacingS,
                          alignment: WrapAlignment.end,
                          children: [saveButton, exportButton],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color bg;
  final Color fg;

  const _StatChip({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.badge.copyWith(
          color: fg,
          fontSize: AttendanceStyleTokens.badgeFontSize,
        ),
      ),
    );
  }
}

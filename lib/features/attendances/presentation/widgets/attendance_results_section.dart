import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/state_card.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_records_table.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_results_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceResultsSection extends StatelessWidget {
  final AttendanceSearchRequest? lastRequest;
  final VoidCallback onExportPressed;
  final VoidCallback onRetry;

  const AttendanceResultsSection({
    super.key,
    required this.lastRequest,
    required this.onExportPressed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = lastRequest;

    if (request == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              color: AppColors.textSecondary,
              size: AppDimensions.spacingXL,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.attendanceEmptySelectionMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<AttendanceBloc, AttendanceState>(
      buildWhen: AttendancePageHelpers.buildWhenResultsChanges,
      builder: (context, state) {
        late final Widget child;

        if (state.fetchStatus == AttendanceStatus.loading) {
          child = StateCard(
            message: l10n.attendanceLoadingMessage,
            icon: Icons.hourglass_top_rounded,
            accent: AppColors.financeDetailAccent,
            accentSoft: AppColors.financeDetailAccentSoft,
            child: const Padding(
              padding: EdgeInsets.only(top: AppDimensions.spacingS),
              child: LinearProgressIndicator(),
            ),
          );
        } else if (state.fetchStatus == AttendanceStatus.failure) {
          child = StateCard(
            message: AttendancePageHelpers.mapAttendanceErrorToMessage(
              l10n,
              state.fetchErrorType,
            ),
            icon: Icons.error_outline,
            accent: AppColors.danger,
            accentSoft: AppColors.financeDetailDangerSoft,
            actionLabel: l10n.refresh,
            onAction: onRetry,
          );
        } else if (state.fetchStatus != AttendanceStatus.success ||
            state.draftRows.isEmpty) {
          child = StateCard(
            message: l10n.attendanceEmptyMessage,
            icon: Icons.inbox_outlined,
            accent: AppColors.textSecondary,
            accentSoft: AppColors.financeDetailMutedSurface,
          );
        } else {
          final totalCount = state.draftRows.length;
          final absentCount = state.draftRows
              .where((row) => !row.present)
              .length;
          final presentCount = totalCount - absentCount;
          final missingReasonsCount = state.draftRows
              .where((row) => !row.present && row.absenceReason == null)
              .length;
          final panelHeight = (MediaQuery.sizeOf(context).height * 0.62)
              .clamp(
                AppDimensions.attendanceResultsPanelMinHeight,
                AppDimensions.attendanceResultsPanelMaxHeight,
              )
              .toDouble();

          Future<void> onValidatePressed() async {
            if (!state.canSave || missingReasonsCount > 0) {
              return;
            }

            if (absentCount == 0) {
              final confirmed = await showAppConfirmationDialog(
                context: context,
                title: l10n.attendanceAllPresentConfirmTitle,
                message: l10n.attendanceAllPresentConfirmMessage(totalCount),
                confirmLabel: l10n.confirm,
                cancelLabel: l10n.cancel,
              );
              if (!context.mounted || !confirmed) {
                return;
              }
            }

            context.read<AttendanceBloc>().add(const AttendanceSaveRequested());
          }

          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AttendanceResultsToolbar(
                classroomName:
                    '${request.selectedLevel.label} - ${request.selectedClassroom.name}',
                formattedDate: MaterialLocalizations.of(
                  context,
                ).formatMediumDate(request.date),
                hasUnsavedChanges: state.hasUnsavedChanges,
                presentCount: presentCount,
                absentCount: absentCount,
                totalCount: totalCount,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              SizedBox(
                height: panelHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.spacingS),
                          child: AttendanceRecordsTable(
                            rows: state.draftRows,
                            scrollable: true,
                          ),
                        ),
                      ),
                      _AttendanceStickyFooter(
                        missingReasonsCount: missingReasonsCount,
                        isSaving: state.saveStatus == AttendanceStatus.loading,
                        canValidate: state.canSave && missingReasonsCount == 0,
                        onExportPressed: onExportPressed,
                        onValidatePressed: onValidatePressed,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: KeyedSubtree(
            key: ValueKey(
              '${state.fetchStatus}-${state.draftRows.length}-${state.fetchErrorType}-${state.saveStatus}-${state.hasUnsavedChanges}-${state.hasValidationErrors}',
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _AttendanceStickyFooter extends StatelessWidget {
  final int missingReasonsCount;
  final bool isSaving;
  final bool canValidate;
  final VoidCallback onExportPressed;
  final VoidCallback onValidatePressed;

  const _AttendanceStickyFooter({
    required this.missingReasonsCount,
    required this.isSaving,
    required this.canValidate,
    required this.onExportPressed,
    required this.onValidatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.cardRadius),
          bottomRight: Radius.circular(AppDimensions.cardRadius),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Row(
          children: [
            Expanded(
              child: Text(
                missingReasonsCount > 0
                    ? l10n.attendanceMissingReasonsStatus(missingReasonsCount)
                    : l10n.attendanceReadyToValidate,
                style: AppTextStyles.body.copyWith(
                  color: missingReasonsCount > 0
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            SecondaryButton(
              label: l10n.attendanceExportAction,
              fullWidth: false,
              onPressed: onExportPressed,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            PrimaryButton(
              label: l10n.attendanceValidateCallAction,
              fullWidth: false,
              isLoading: isSaving,
              onPressed: canValidate ? onValidatePressed : null,
            ),
          ],
        ),
      ),
    );
  }
}

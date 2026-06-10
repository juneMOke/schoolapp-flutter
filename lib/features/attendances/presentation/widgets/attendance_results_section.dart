import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/state_card.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_records_mobile_list.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_results_toolbar.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_save_overlay.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendanceResultsSection extends StatelessWidget {
  final AttendanceSearchRequest? lastRequest;
  final VoidCallback onRetry;

  const AttendanceResultsSection({
    super.key,
    required this.lastRequest,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = lastRequest;

    if (request == null) {
      return EteeloEmptyResult(
        medallionIcon: Icons.calendar_today_outlined,
        label: l10n.attendanceSelectClassTitle,
        description: l10n.attendanceEmptySelectionMessage,
        fullWidthCard: true,
        minHeight: 260,
        cardPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingXL,
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
          final justifiedCount = state.draftRows
              .where(
                (r) =>
                    !r.present &&
                    r.absenceReason != null &&
                    r.absenceReason != AbsenceReason.unjustified,
              )
              .length;
          final unjustifiedCount = state.draftRows
              .where((r) => r.absenceReason == AbsenceReason.unjustified)
              .length;
          final missingReasonsCount = state.draftRows
              .where((row) => !row.present && row.absenceReason == null)
              .length;
          final panelHeight = (MediaQuery.sizeOf(context).height * 0.62)
              .clamp(
                AppDimensions.attendanceResultsPanelMinHeight,
                AppDimensions.attendanceResultsPanelMaxHeight,
              )
              .toDouble();

          Future<void> onSaveCallPressed() async {
            if (!state.canSave || missingReasonsCount > 0) return;

            if (absentCount == 0) {
              final confirmed = await showAppConfirmationDialog(
                context: context,
                title: l10n.attendanceAllPresentConfirmTitle,
                message: l10n.attendanceAllPresentConfirmMessage(totalCount),
                confirmLabel: l10n.confirm,
                cancelLabel: l10n.cancel,
              );
              if (!context.mounted || !confirmed) return;
            }

            if (!context.mounted) return;
            await showAttendanceSaveOverlay(
              context: context,
              attendanceBloc: context.read<AttendanceBloc>(),
              classroomName: request.selectedClassroom.name,
              date: request.date,
              presentCount: presentCount,
              justifiedCount: justifiedCount,
              unjustifiedCount: unjustifiedCount,
            );
          }

          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AttendanceActionBar(
                isSaving: state.saveStatus == AttendanceStatus.loading,
                canSave: state.canSave && missingReasonsCount == 0,
                onMarkAllPresent: () => context.read<AttendanceBloc>().add(
                  const AttendanceMarkAllPresentRequested(),
                ),
                onSaveCall: onSaveCallPressed,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              AttendanceResultsToolbar(
                presentCount: presentCount,
                justifiedCount: justifiedCount,
                unjustifiedCount: unjustifiedCount,
                pendingCount: missingReasonsCount,
                total: totalCount,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              SizedBox(
                height: panelHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
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
                          child: AttendanceRecordsMobileList(
                            rows: state.draftRows,
                            classroomName: request.selectedClassroom.name,
                            shrinkWrap: false,
                          ),
                        ),
                        if (missingReasonsCount > 0)
                          _RappelAmbreBar(
                            missingReasonsCount: missingReasonsCount,
                          ),
                      ],
                    ),
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

class _AttendanceActionBar extends StatelessWidget {
  final bool isSaving;
  final bool canSave;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onSaveCall;

  const _AttendanceActionBar({
    required this.isSaving,
    required this.canSave,
    required this.onMarkAllPresent,
    required this.onSaveCall,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        EteeloButton.secondary(
          label: l10n.attendanceMarkAllPresentAction,
          onPressed: isSaving ? null : onMarkAllPresent,
          fullWidth: false,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        EteeloButton.primary(
          label: l10n.attendanceSaveCallAction,
          isLoading: isSaving,
          onPressed: canSave ? onSaveCall : null,
          fullWidth: false,
        ),
      ],
    );
  }
}

class _RappelAmbreBar extends StatelessWidget {
  final int missingReasonsCount;

  const _RappelAmbreBar({required this.missingReasonsCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.cardRadius),
          bottomRight: Radius.circular(AppDimensions.cardRadius),
        ),
        border: Border(
          top: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 15,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Expanded(
              child: Text(
                l10n.attendanceMissingReasonsStatus(missingReasonsCount),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

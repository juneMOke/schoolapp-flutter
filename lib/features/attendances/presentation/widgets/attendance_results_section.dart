import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
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
      return StateCard(
        message: l10n.attendanceInvitationMessage,
        icon: Icons.search_rounded,
        accent: AppColors.financeDetailAccent,
        accentSoft: AppColors.financeDetailAccentSoft,
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
          final stats = AttendanceStats.fromRecords(state.records);

          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AttendanceResultsToolbar(
                stats: stats,
                modifiedCount: state.modifiedCount,
                hasUnsavedChanges: state.hasUnsavedChanges,
                hasValidationErrors: state.hasValidationErrors,
                isSaving: state.saveStatus == AttendanceStatus.loading,
                onExportPressed: onExportPressed,
                onSavePressed: state.canSave
                    ? () => context.read<AttendanceBloc>().add(
                          const AttendanceSaveRequested(),
                        )
                    : null,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              AttendanceRecordsTable(
                rows: state.draftRows,
                modifiedStudentIds: state.modifiedStudentIds,
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

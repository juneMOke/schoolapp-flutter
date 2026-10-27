import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_filter_empty.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_close_dialog.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_closure.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_filters.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_table.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_totals.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/states/hr_presence_results_error_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/staff_attendance_notices.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le récapitulatif sous la barre : le mois et sa navigation, les totaux du
/// serveur, la clôture, puis les agents.
class HrPresenceRecapBody extends StatelessWidget {
  final HrPresenceRecapState state;
  final ValueChanged<HrAttendanceRecapRow> onOpen;

  const HrPresenceRecapBody({
    super.key,
    required this.state,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceRecapCubit>();
    final recap = state.recap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrPersonnelHeader(subtitle: l10n.hrPresenceRecapSubtitle),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PresenceMonthNav(
              month: state.month,
              isCurrent: state.isCurrentMonth,
              onPrevious: state.canStepBack
                  ? () => unawaited(cubit.stepMonth(-1))
                  : null,
              onNext: () => unawaited(cubit.stepMonth(1)),
              onCurrent: () => unawaited(cubit.goCurrentMonth()),
              onPick: () async {
                final picked = await pickPresenceMonth(
                  context,
                  month: state.month,
                  firstMonth: state.firstMonth,
                  lastMonth: state.currentMonth,
                );
                if (picked != null && !cubit.isClosed) {
                  unawaited(cubit.showMonth(picked));
                }
              },
            ),
            if (recap != null && recap.classDays > 0)
              Text(
                recap.toDate
                    ? l10n.hrPresenceRecapClassDaysToDate(recap.classDays)
                    : l10n.hrPresenceRecapClassDays(recap.classDays),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _content(context, l10n, cubit),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    HrPresenceRecapCubit cubit,
  ) {
    final recap = state.recap;
    switch (state.status) {
      case HrPresenceRecapStatus.loading:
        return const EteeloListSkeleton(rowCount: 8);
      case HrPresenceRecapStatus.failure:
        return HrPresenceResultsErrorState(
          failure: state.failure,
          onRetry: () => unawaited(cubit.retry()),
        );
      case HrPresenceRecapStatus.ready:
        if (recap == null) return const EteeloListSkeleton(rowCount: 8);
        // Un mois sans jour de classe : rien à clôturer pour la Paie.
        if (recap.classDays == 0) {
          return PresenceHolidayState(
            month: state.month,
            onCurrent: () => unawaited(cubit.goCurrentMonth()),
          );
        }
        final rows = state.visibleRows;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HrPresenceRecapTotals(recap: recap, unsynced: state.unsynced),
            const SizedBox(height: AppSpacing.lg),
            HrPresenceRecapClosure(
              state: state,
              onClose: () => unawaited(_close(context, recap)),
            ),
            const SizedBox(height: AppSpacing.lg),
            HrPresenceRecapFilters(
              total: state.searchedCount,
              counts: state.contractCounts,
              selected: state.contract,
              onContract: cubit.toggleContract,
              text: state.text,
              onText: cubit.setText,
            ),
            const SizedBox(height: AppSpacing.md),
            if (rows.isEmpty)
              PresenceFilterEmpty(
                label: l10n.staffAttendanceRecapEmptyFilter,
                allMarked: false,
                onShowAll: cubit.clearFilters,
              )
            else
              EteeloPanelCard(
                child: HrPresenceRecapTable(rows: rows, onOpen: onOpen),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.hrPresenceRecapLegend,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ],
        );
    }
  }

  Future<void> _close(BuildContext context, HrAttendanceRecap recap) async {
    final cubit = context.read<HrPresenceRecapCubit>();
    final confirmed = await EteeloFormDialog.show<bool>(
      context,
      HrPresenceCloseDialog(
        recap: recap,
        monthLabel: PresenceLabels.month(
          MaterialLocalizations.of(context),
          recap.month,
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final notice = await cubit.closeMonth();
    if (notice != null && context.mounted) {
      showStaffAttendanceNotice(context, notice);
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_reason_dialog.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_filter_empty.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_close_dialog.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_closure.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_filters.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_hero.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_table.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/states/hr_presence_results_error_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/staff_attendance_notices.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le récapitulatif sous la barre : le bandeau (le mois et les totaux du
/// serveur), la clôture, puis les agents.
class HrPresenceRecapBody extends StatelessWidget {
  final HrPresenceRecapState state;
  final ValueChanged<HrAttendanceRecapRow> onOpen;

  /// Le motif d'une réouverture : 1 à 500 caractères (contrat back).
  static const reopenReasonMax = 500;

  const HrPresenceRecapBody({
    super.key,
    required this.state,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceRecapCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrPersonnelHeader(subtitle: l10n.hrPresenceRecapSubtitle),
        const SizedBox(height: AppSpacing.md),
        // Le mois pilote tout l'écran : il reste au bandeau pendant le
        // chargement et sur une erreur.
        HrPresenceRecapHero(state: state),
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
            HrPresenceRecapClosure(
              state: state,
              onClose: () => unawaited(_close(context, recap)),
              onReopen: () => unawaited(_reopen(context, recap)),
            ),
            const SizedBox(height: AppSpacing.lg),
            HrPresenceRecapFilters(
              total: state.searchedCount,
              counts: state.contractCounts,
              selected: state.contract,
              onContract: cubit.toggleContract,
              text: state.text,
              onText: cubit.setText,
              // Seulement là où une retenue peut exister.
              deducted: HrPresenceRecapColumns.of(recap).deduction
                  ? (count: state.deductedCount, selected: state.deductedOnly)
                  : null,
              onDeducted: cubit.toggleDeducted,
            ),
            const SizedBox(height: AppSpacing.md),
            if (rows.isEmpty)
              PresenceFilterEmpty(
                label: l10n.staffAttendanceRecapEmptyFilter,
                allMarked: false,
                onShowAll: cubit.clearFilters,
              )
            else
              HrPresenceRecapTable(
                rows: rows,
                onOpen: onOpen,
                columns: HrPresenceRecapColumns.of(recap),
                unsyncedByAgent: state.unsyncedByAgent,
                // Filtré, le tableau n'est plus le mois entier : pas de
                // total, plutôt qu'un total qui ne s'additionne pas.
                total: state.hasFilters ? null : recap,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                if (HrPresenceRecapColumns.of(recap).deduction &&
                    recap.workingDays > 0)
                  l10n.hrPresenceRecapLegendPay(recap.workingDays),
                l10n.hrPresenceRecapLegend,
              ].join(' · '),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ],
        );
    }
  }

  /// Rouvrir exige un motif : il est consigné avec le geste.
  Future<void> _reopen(BuildContext context, HrAttendanceRecap recap) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceRecapCubit>();
    final reason = await EteeloReasonDialog.show(
      context,
      EteeloReasonDialog(
        title: l10n.hrPresenceRecapReopenTitle(
          PresenceLabels.month(MaterialLocalizations.of(context), recap.month),
        ),
        confirmLabel: l10n.hrPresenceRecapReopen,
        cancelLabel: l10n.hrPresenceRecapReopenCancel,
        fieldLabel: l10n.hrPresenceRecapReopenReason,
        requiredError: l10n.hrPresenceRecapReopenReasonRequired,
        helper: l10n.hrPresenceRecapReopenHelper,
        maxLength: HrPresenceRecapBody.reopenReasonMax,
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    final notice = await cubit.reopenMonth(reason);
    if (notice != null && context.mounted) {
      showStaffAttendanceNotice(context, notice);
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_card_frame.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_filter_empty.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/dialogs/staff_month_close_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_recap_table.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_recap_totals.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// L'onglet « Récapitulatif du mois » : filtres, totaux, tableau, et la
/// clôture vers la Paie.
class StaffRecapTab extends StatelessWidget {
  final StaffAttendanceState state;

  const StaffRecapTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StaffAttendanceCubit>();
    final recap = state.recap;
    final closed = recap.ledger.isClosed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            PresenceMonthNav(
              month: state.month,
              isCurrent: state.isCurrentMonth,
              onPrevious: state.canStepMonthBack
                  ? () => unawaited(cubit.stepMonth(-1))
                  : null,
              onNext: () => unawaited(cubit.stepMonth(1)),
              onCurrent: () => unawaited(cubit.goCurrentMonth()),
            ),
            if (state.canCloseMonth && !recap.ledger.isHoliday)
              PermissionGate.access(
                kStaffAttendanceManageAccess,
                child: EteeloButton.primary(
                  label: l10n.staffAttendanceClose,
                  icon: Icons.lock,
                  onPressed: recap.isEmpty
                      ? null
                      : () => unawaited(_close(context, recap)),
                  fullWidth: false,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (closed) ...[
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.present,
            message: l10n.staffAttendanceMonthClosedBanner,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (recap.ledger.isHoliday)
          PresenceHolidayState(
            month: state.month,
            onCurrent: () => unawaited(cubit.goCurrentMonth()),
          )
        else ...[
          _Filters(
            recap: recap,
            query: state.recapQuery,
            onContract: cubit.toggleRecapContract,
            onText: cubit.setRecapText,
          ),
          const SizedBox(height: AppSpacing.md),
          StaffRecapTotals(recap: recap),
          const SizedBox(height: AppSpacing.md),
          if (recap.isFilteredEmpty)
            PresenceFilterEmpty(
              label: l10n.staffAttendanceRecapEmptyFilter,
              allMarked: false,
              onShowAll: cubit.resetRecapFilters,
            )
          else
            PresenceCardFrame(
              child: StaffRecapTable(
                rows: recap.rows,
                onOpen: (row) => cubit.openAgent(row.member.id),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.staffAttendanceRecapLegend,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _close(BuildContext context, StaffMonthRecap recap) async {
    final cubit = context.read<StaffAttendanceCubit>();
    final confirmed = await EteeloFormDialog.show<bool>(
      context,
      StaffMonthCloseDialog(
        recap: recap,
        monthLabel: PresenceLabels.month(
          MaterialLocalizations.of(context),
          recap.ledger.month,
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await cubit.perform((c) => c.closeMonth(recap.ledger.month));
  }
}

class _Filters extends StatelessWidget {
  final StaffMonthRecap recap;
  final StaffRecapQuery query;
  final ValueChanged<StaffContractFilter?> onContract;
  final ValueChanged<String> onText;

  const _Filters({
    required this.recap,
    required this.query,
    required this.onContract,
    required this.onText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            EteeloFilterChip(
              label: l10n.presenceMarkFilterAll,
              count: recap.all.length,
              selected: query.contract == null,
              color: AppColors.bleuArdoise,
              soft: AppColors.bleuArdoiseSoft,
              ink: AppColors.bleuArdoise,
              onTap: () => onContract(null),
            ),
            for (final filter in StaffContractFilter.values)
              if (filter != StaffContractFilter.none ||
                  (recap.byContract[filter] ?? 0) > 0)
                _contractChip(l10n, filter),
          ],
        ),
        StaffSearchToolbar(
          text: query.text,
          label: l10n.staffAttendanceSearchLabel,
          placeholder: l10n.staffAttendanceSearchPlaceholder,
          onTextChanged: onText,
        ),
      ],
    );
  }

  Widget _contractChip(AppLocalizations l10n, StaffContractFilter filter) {
    final tone = StaffContractTone.ofFilter(filter);
    return EteeloFilterChip(
      label: StaffLabels.contractFilter(l10n, filter),
      count: recap.byContract[filter] ?? 0,
      selected: query.contract == filter,
      color: tone.color,
      soft: tone.soft,
      ink: tone.ink,
      icon: tone.icon,
      onTap: () => onContract(filter),
    );
  }
}

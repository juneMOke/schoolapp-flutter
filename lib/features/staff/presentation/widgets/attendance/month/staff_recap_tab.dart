import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_card_frame.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_warning.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/dialogs/staff_month_close_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_holiday_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_month_nav.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_recap_table.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_recap_totals.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_filter_chip.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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
            StaffMonthNav(
              month: state.month,
              isCurrent: state.month == state.today.substring(0, 7),
              onPrevious: () => unawaited(cubit.stepMonth(-1)),
              onNext: () => unawaited(cubit.stepMonth(1)),
              onCurrent: () => unawaited(cubit.goCurrentMonth()),
            ),
            if (!closed && !recap.ledger.isHoliday)
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
          StaffAttendanceWarning(
            icon: Icons.lock_outline,
            tone: StaffAttendanceStatus.present,
            message: l10n.staffAttendanceMonthClosedBanner,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (recap.ledger.isHoliday)
          StaffHolidayState(
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
            EteeloEmptyResult(
              label: l10n.staffAttendanceRecapEmptyFilter,
              medallionIcon: Icons.search_rounded,
              fullWidthCard: true,
              primaryAction: EteeloButton.primary(
                label: l10n.staffAttendanceShowAll,
                icon: Icons.restart_alt,
                onPressed: cubit.resetRecapFilters,
                fullWidth: false,
              ),
            )
          else
            StaffAttendanceCardFrame(
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
    final confirmed = await StaffAttendanceDialog.show<bool>(
      context,
      StaffMonthCloseDialog(
        recap: recap,
        monthLabel: StaffAttendanceLabels.month(
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
            StaffFilterChip(
              label: l10n.staffAttendanceFilterAll,
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
    return StaffFilterChip(
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

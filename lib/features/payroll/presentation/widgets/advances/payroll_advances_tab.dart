import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_advance_table.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_advance_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_reason_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre des avances : encours, déduit ce mois, soldées ; le filtre ;
/// le tableau ; l'octroi pour l'économe.
class PayrollAdvancesTab extends StatelessWidget {
  final PayrollState state;

  const PayrollAdvancesTab({super.key, required this.state});

  List<SalaryAdvance> get _visible => [
    for (final advance in state.snapshot.advances)
      if (switch (state.advanceFilter) {
        PayrollAdvanceFilter.ongoing => advance.isLive && !advance.isSettled,
        PayrollAdvanceFilter.settled => advance.isSettled,
        PayrollAdvanceFilter.all => true,
      })
        advance,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final advances = state.snapshot.advances;
    final ongoing = advances.where((a) => a.isLive && !a.isSettled);
    final settled = advances.where((a) => a.isSettled).length;
    final outstanding = PayrollLabels.perCurrency(
      ongoing.map((a) => (a.remainingInCents, a.amount.currency)),
    );
    final thisMonth = PayrollLabels.perCurrency([
      for (final line in state.view?.lines ?? const [])
        (line.advanceInCents, line.currency),
    ]);
    final visible = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloKpiBand(
          cards: [
            EteeloKpiCardData(
              label: l10n.payrollAdvancesOutstanding,
              valueLines: outstanding,
              accent: AppColors.staffAttendanceLateInk,
              accentSoft: AppColors.staffAttendanceLateSoft,
              icon: Icons.hourglass_bottom,
            ),
            EteeloKpiCardData(
              label: l10n.payrollAdvancesThisMonth,
              valueLines: thisMonth,
              accent: AppColors.staffAttendanceAbsentInk,
              accentSoft: AppColors.staffAttendanceAbsentSoft,
              icon: Icons.remove_circle_outline,
            ),
            EteeloKpiCardData(
              label: l10n.payrollAdvancesSettled,
              value: settled,
              accent: AppColors.staffAttendancePresentInk,
              accentSoft: AppColors.staffAttendancePresentSoft,
              icon: Icons.task_alt,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            PayrollChoiceChips<PayrollAdvanceFilter>(
              values: PayrollAdvanceFilter.values,
              selected: state.advanceFilter,
              label: (filter) => switch (filter) {
                PayrollAdvanceFilter.ongoing =>
                  l10n.payrollAdvancesFilterOngoing,
                PayrollAdvanceFilter.settled =>
                  l10n.payrollAdvancesFilterSettled,
                PayrollAdvanceFilter.all => l10n.payrollAdvancesFilterAll,
              },
              onSelected: cubit.setAdvanceFilter,
            ),
            if (canWrite)
              EteeloButton.primary(
                label: l10n.payrollAdvanceNew,
                icon: Icons.add,
                onPressed: () => _grant(context),
                fullWidth: false,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          EteeloEmptyResult(
            label: advances.isEmpty
                ? l10n.payrollAdvancesEmpty
                : l10n.payrollAdvancesEmptyFilter,
            medallionIcon: Icons.volunteer_activism_outlined,
            primaryAction: advances.isEmpty && canWrite
                ? EteeloButton.secondary(
                    label: l10n.payrollAdvanceNew,
                    onPressed: () => _grant(context),
                    fullWidth: false,
                  )
                : null,
          )
        else if (state.view case final view?)
          PayrollAdvanceTable(
            advances: visible,
            snapshot: state.snapshot,
            view: view,
            onCancel: canWrite ? (a) => _cancel(context, a) : null,
          ),
      ],
    );
  }

  Future<void> _grant(BuildContext context) async {
    final cubit = context.read<PayrollCubit>();
    final draft = await PayrollAdvanceDialog.show(
      context,
      PayrollAdvanceDialog(snapshot: state.snapshot, today: state.today),
    );
    if (draft == null || !context.mounted) return;
    await cubit.perform(
      (commands) => commands.grantAdvance(
        cubit.state.snapshot,
        draft,
        name: PayrollLedgerActions(context).nameOf(draft.staffMemberId),
        amount: MoneyFormat.format(draft.amount),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, SalaryAdvance advance) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final reason = await PayrollReasonDialog.show(
      context,
      title: l10n.payrollAdvanceCancel,
      confirmLabel: l10n.payrollAdvanceCancel,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await cubit.perform(
      (commands) =>
          commands.cancelAdvance(cubit.state.snapshot, advance, reason),
    );
  }
}

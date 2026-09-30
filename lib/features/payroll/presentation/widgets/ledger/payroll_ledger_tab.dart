import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_action_bar.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_kpis.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_filters.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_header.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_notices.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_table.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_regularizations.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_settings_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le livre de paie du mois : bandeau et circuit, barre d'action, bandeaux,
/// indicateurs, filtres et tableau.
class PayrollLedgerTab extends StatelessWidget {
  final PayrollState state;

  const PayrollLedgerTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    if (view == null) return const SizedBox.shrink();
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final actions = PayrollLedgerActions(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: PayrollLedgerHeader(state: state)),
            const PayrollSettingsButton(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PayrollActionBar(view: view),
        PayrollLedgerNotices(view: view),
        PayrollRegularizations(
          disbursements: PayrollLedger.toRegularize(state.snapshot),
          canWrite: canWrite,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (view.lines.isEmpty)
          _Empty(state: state)
        else ...[
          PayrollKpis(view: view),
          const SizedBox(height: AppSpacing.lg),
          PayrollLedgerFilters(state: state),
          const SizedBox(height: AppSpacing.md),
          if (state.visibleLines.isEmpty)
            _Empty(state: state)
          else
            PayrollLedgerTable(
              view: view,
              snapshot: state.snapshot,
              lines: state.visibleLines,
              canWrite: canWrite,
              onPayout: (line) => actions.openPayout(line, canWrite: canWrite),
              onOpen: (line) => view.isEditable && canWrite
                  ? actions.editVariables(line)
                  : context.read<PayrollCubit>().openPayslip(
                      line.staffMemberId,
                    ),
            ),
        ],
      ],
    );
  }
}

/// Personne à payer, aucune paie ce mois-là, ou un filtre qui ne garde rien.
class _Empty extends StatelessWidget {
  final PayrollState state;

  const _Empty({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final filtered =
        state.hasFilters && (state.view?.lines.isNotEmpty ?? false);
    if (filtered) {
      return EteeloEmptyResult(
        label: state.payFilter == PayrollPayFilter.toPay
            ? l10n.payrollEmptyAllPaid
            : l10n.payrollEmptyFilter,
        medallionIcon: Icons.filter_alt_off_outlined,
        primaryAction: EteeloButton.secondary(
          label: l10n.payrollShowAll,
          onPressed: cubit.resetFilters,
          fullWidth: false,
        ),
      );
    }
    final noStaff = state.snapshot.contractsByMember.isEmpty;
    return EteeloEmptyResult(
      label: noStaff ? l10n.payrollEmptyStaff : l10n.payrollEmptyMonth,
      description: noStaff ? l10n.payrollEmptyStaffHint : null,
      medallionIcon: Icons.receipt_long_outlined,
      primaryAction: state.isCurrentMonth
          ? null
          : EteeloButton.secondary(
              label: l10n.payrollCurrentMonth,
              onPressed: cubit.goCurrentMonth,
              fullWidth: false,
            ),
    );
  }
}

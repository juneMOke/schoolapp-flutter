import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_actions.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_agent_navigation.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_action_bar.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_arrears_banner.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_kpis.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_filters.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_header.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_notice_stack.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_notices.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_table.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_payout_bar.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_regularizations.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le livre de paie du mois : bandeau et circuit, barre d'action, bandeaux,
/// indicateurs, filtres et tableau.
class PayrollLedgerView extends StatelessWidget {
  final PayrollState state;

  const PayrollLedgerView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    if (view == null) return const SizedBox.shrink();
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final actions = PayrollLedgerActions(context);
    // Ctrl+P : l'état de paie du mois validé, composé par le serveur (T16).
    return PageActionShortcut(
      action: PageAction.print,
      onInvoke: view.phase.isLocked
          ? PayrollPayslipActions(context).openStatement
          : null,
      child: _ledger(context, view, actions, canWrite),
    );
  }

  Widget _ledger(
    BuildContext context,
    PayrollMonthView view,
    PayrollLedgerActions actions,
    bool canWrite,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayrollLedgerHeader(state: state),
        PayrollActionBar(view: view),
        const SizedBox(height: AppSpacing.lg),
        // Les chiffres d'abord, comme sur les autres écrans ; puis une seule
        // zone de bandeaux, la plus grave visible.
        if (view.lines.isNotEmpty) ...[
          PayrollKpis(view: view),
          const SizedBox(height: AppSpacing.lg),
        ],
        _notices(context, view, canWrite),
        const SizedBox(height: AppSpacing.lg),
        if (view.lines.isEmpty)
          _Empty(state: state)
        else ...[
          PayrollPayoutBar(
            view: view,
            canEdit: canWrite && view.isEditable,
            onEdit: actions.editPayoutPolicy,
          ),
          const SizedBox(height: AppSpacing.lg),
          PayrollLedgerFilters(state: state),
          const SizedBox(height: AppSpacing.md),
          if (state.visibleLines.isEmpty)
            _Empty(state: state)
          else
            PayrollLedgerViewle(
              view: view,
              snapshot: state.snapshot,
              lines: state.visibleLines,
              canWrite: canWrite,
              onPayout: (line) => actions.openPayout(line, canWrite: canWrite),
              onOpen: (line) => PayrollAgentNavigation.open(
                context,
                agentId: line.staffMemberId,
                month: view.month,
              ),
              onEdit: view.isEditable && canWrite
                  ? actions.editVariables
                  : null,
            ),
        ],
      ],
    );
  }

  /// Les alertes d'abord, toutes visibles : l'argent parti sans trace, puis
  /// les refus, renvois et blocages du mois ; ensuite les informations, dont
  /// les arriérés des mois antérieurs. Un mois neuf replie à nouveau.
  Widget _notices(BuildContext context, PayrollMonthView view, bool canWrite) {
    final toRegularize = PayrollLedger.toRegularize(state.snapshot);
    final month = PayrollLedgerNotices.of(context, view);
    return PayrollNoticeStack(
      key: ValueKey(view.month),
      alerts: [
        if (toRegularize.isNotEmpty)
          PayrollRegularizations(
            disbursements: toRegularize,
            canWrite: canWrite,
          ),
        ...month.alerts,
      ],
      infos: [
        ...month.infos,
        if (PayrollArrearsBanner.shows(state.snapshot, view))
          PayrollArrearsBanner(snapshot: state.snapshot, view: view),
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
        label: state.payFilter == PayrollPayFilter.unpaid
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

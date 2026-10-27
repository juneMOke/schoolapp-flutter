import 'dart:async';

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
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_month_location.dart';
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

/// Le livre de paie du mois : bandeau et circuit, bandeaux, geste du mois et
/// versement, indicateurs, filtres et tableau.
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
    final gap = const SizedBox(height: AppSpacing.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayrollLedgerHeader(state: state),
        gap,
        // Les alertes d'abord ; puis ce que l'école doit encore, le geste du
        // mois et sa politique de versement ; enfin les chiffres.
        _notices(context, view, canWrite),
        if (PayrollArrearsBanner.shows(state.snapshot, view)) ...[
          PayrollArrearsBanner(snapshot: state.snapshot, view: view),
          gap,
        ],
        PayrollActionBar(view: view),
        if (view.lines.isNotEmpty) ...[
          if (view.hasReducedPayout || (canWrite && view.isEditable)) ...[
            gap,
            PayrollPayoutBar(
              view: view,
              canEdit: canWrite && view.isEditable,
              onEdit: actions.editPayoutPolicy,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PayrollKpis(view: view),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (view.lines.isEmpty)
          _Empty(state: state)
        else ...[
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
              onOpen: (line) => unawaited(
                PayrollAgentNavigation.open(
                  context,
                  agentId: line.staffMemberId,
                  month: view.month,
                  screenQuery: {
                    if (!state.isCurrentMonth)
                      PayrollMonthLocation.monthParam: view.month,
                  },
                ),
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
  /// les refus, renvois et blocages du mois ; ensuite les informations. Un
  /// mois neuf replie à nouveau. Rien à dire : rien, pas même un espace.
  Widget _notices(BuildContext context, PayrollMonthView view, bool canWrite) {
    final toRegularize = PayrollLedger.toRegularize(state.snapshot);
    final month = PayrollLedgerNotices.of(context, view);
    final alerts = [
      if (toRegularize.isNotEmpty)
        PayrollRegularizations(disbursements: toRegularize, canWrite: canWrite),
      ...month.alerts,
    ];
    if (alerts.isEmpty && month.infos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PayrollNoticeStack(
        key: ValueKey(view.month),
        alerts: alerts,
        infos: month.infos,
      ),
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

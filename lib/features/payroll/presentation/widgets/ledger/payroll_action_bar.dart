import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une phrase d'état et le seul geste possible, selon l'état affiché et les
/// droits de la session — plus de bascule de rôle : le rôle vient du jeton.
class PayrollActionBar extends StatelessWidget {
  final PayrollMonthView view;

  const PayrollActionBar({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final canManage = PermissionGate.allows(
      context,
      kPayrollManageAccess.requires,
    );
    final actions = PayrollLedgerActions(context);
    // Un geste bloqué reste visible mais inactif : le bandeau dit pourquoi.
    Widget primary(
      String label,
      IconData icon,
      Future<void> Function() on, {
      bool blocked = false,
    }) => EteeloButton.primary(
      label: label,
      icon: icon,
      onPressed: blocked ? null : on,
      fullWidth: false,
    );
    Widget secondary(String label, IconData icon, Future<void> Function() on) =>
        EteeloButton.secondary(
          label: label,
          icon: icon,
          onPressed: on,
          fullWidth: false,
        );
    final (String message, List<Widget> buttons) = switch (view.phase) {
      PayrollPhase.draft when canWrite => (
        l10n.payrollBarDraftWrite,
        [
          primary(
            l10n.payrollActionSubmit,
            Icons.send_outlined,
            actions.submit,
            blocked: view.submitBlocker != null,
          ),
        ],
      ),
      PayrollPhase.draft => (l10n.payrollBarDraftRead, <Widget>[]),
      PayrollPhase.submitted when canManage => (
        l10n.payrollBarSubmittedManage,
        [
          secondary(l10n.payrollActionReturn, Icons.reply, actions.sendBack),
          primary(
            l10n.payrollActionValidate,
            Icons.lock_outline,
            actions.validate,
            blocked: view.validateBlocker != null,
          ),
        ],
      ),
      PayrollPhase.submitted => (l10n.payrollBarSubmittedWrite, <Widget>[]),
      PayrollPhase.validated || PayrollPhase.paid => (
        view.phase == PayrollPhase.paid
            ? l10n.payrollBarPaid
            : l10n.payrollBarValidated(view.remainingCount),
        [
          if (canManage && view.reopenBlocker == null)
            secondary(
              l10n.payrollActionReopen,
              Icons.lock_open_outlined,
              actions.reopen,
            ),
          primary(
            l10n.payrollActionDiffuse,
            Icons.share_outlined,
            () async =>
                context.read<PayrollCubit>().setTab(PayrollTab.payslips),
          ),
        ],
      ),
      _ => (l10n.payrollBarInFlight, <Widget>[]),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: buttons,
          ),
        ],
      ),
    );
  }
}

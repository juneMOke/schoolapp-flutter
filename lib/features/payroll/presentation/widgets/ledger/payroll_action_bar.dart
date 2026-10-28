import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_callout.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_diffuse_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une phrase d'état, ce qu'elle demande, et le seul geste possible, selon l'état affiché et les
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
    final payslips = PayrollPayslipActions(context);
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
    final (
      String message,
      String? detail,
      IconData icon,
      List<Widget> buttons,
    ) = switch (view.phase) {
      PayrollPhase.draft when canWrite => (
        l10n.payrollBarDraftWrite,
        l10n.payrollBarDraftWriteDetail,
        Icons.edit_outlined,
        [
          primary(
            l10n.payrollActionSubmit,
            Icons.send_outlined,
            actions.submit,
            blocked: view.submitBlocker != null,
          ),
        ],
      ),
      PayrollPhase.draft => (
        l10n.payrollBarDraftRead,
        null,
        Icons.edit_note_outlined,
        <Widget>[],
      ),
      PayrollPhase.submitted when canManage => (
        l10n.payrollBarSubmittedManage,
        l10n.payrollBarSubmittedManageDetail,
        Icons.fact_check_outlined,
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
      PayrollPhase.submitted => (
        l10n.payrollBarSubmittedWrite,
        null,
        Icons.hourglass_top_outlined,
        <Widget>[],
      ),
      PayrollPhase.validated || PayrollPhase.paid => (
        view.phase == PayrollPhase.paid
            ? l10n.payrollBarPaid
            : l10n.payrollBarValidated(view.remainingCount),
        view.phase == PayrollPhase.paid ? null : l10n.payrollBarValidatedDetail,
        view.phase == PayrollPhase.paid ? Icons.task_alt : Icons.lock_outline,
        [
          if (canManage && view.reopenBlocker == null)
            secondary(
              l10n.payrollActionReopen,
              Icons.lock_open_outlined,
              actions.reopen,
            ),
          // L'état de paie du mois, composé par le serveur (T16) — Ctrl+P.
          secondary(
            l10n.payrollStatementPrint,
            Icons.print_outlined,
            payslips.openStatement,
          ),
          primary(
            l10n.payrollActionDiffuse,
            Icons.share_outlined,
            () => PayrollDiffuseDialog.show(
              context,
              PayrollDiffuseDialog(
                onCollection: () => payslips.openPdf(null),
                onWhatsapp: payslips.whatsapp,
                phoneOf: payslips.phoneOf,
              ),
            ),
          ),
        ],
      ),
      _ => (
        l10n.payrollBarInFlight,
        null,
        Icons.cloud_upload_outlined,
        <Widget>[],
      ),
    };
    return PayrollCallout(
      icon: icon,
      title: message,
      details: [?detail],
      action: buttons.isEmpty
          ? null
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: buttons,
            ),
    );
  }
}

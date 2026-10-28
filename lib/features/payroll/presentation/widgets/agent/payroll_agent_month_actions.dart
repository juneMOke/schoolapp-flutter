import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_preview_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes du mois affiché, ceux du livre et des bulletins : éléments
/// variables (brouillon), bulletin PDF — scellé après validation, provisoire
/// avant, en ligne —, WhatsApp, et le versement ou sa consultation.
class PayrollAgentMonthActions extends StatelessWidget {
  final PayrollAgentMonth month;
  final PayrollSnapshot snapshot;

  const PayrollAgentMonthActions({
    super.key,
    required this.month,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final line = month.line;
    final view = month.view;
    final ledger = PayrollLedgerActions(context);
    final payslips = PayrollPayslipActions(context);
    final settlement = month.settlement;
    // Une ligne v1 est réputée versée : rien à verser, jamais deux fois.
    final remaining = month.remainingInCents;
    final shared =
        snapshot.shareTraces[PayrollSnapshot.traceKey(
          month.month,
          line.staffMemberId,
        )]?[PayrollShareChannel.whatsapp] !=
        null;
    final phone = payslips.phoneOf(line.staffMemberId);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (view.isEditable && canWrite)
          EteeloButton.secondary(
            label: l10n.payrollVarsTitle,
            icon: Icons.edit_outlined,
            onPressed: () => ledger.editVariables(line),
            size: EteeloButtonSize.regular,
            fullWidth: false,
          ),
        if (month.isLocked)
          EteeloButton.secondary(
            label: l10n.payrollPayslipDownload,
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () => payslips.openPdf(line),
            size: EteeloButtonSize.regular,
            fullWidth: false,
          )
        else
          PayrollPreviewButton(line: line, inline: true),
        if (month.isLocked && line.netInCents > 0)
          EteeloButton.success(
            label: shared
                ? l10n.payrollAgentWhatsappAgain
                : l10n.payrollPayslipWhatsapp,
            icon: Icons.chat_outlined,
            onPressed: phone == null ? null : () => payslips.whatsapp(line),
            size: EteeloButtonSize.regular,
            fullWidth: false,
          ),
        if (view.canPay && canWrite && remaining > 0)
          EteeloButton.primary(
            label: l10n.payrollAgentPayRemaining(
              PayrollLabels.money(remaining, line.currency),
            ),
            icon: Icons.payments_outlined,
            onPressed: () => ledger.openPayout(line, canWrite: true),
            fullWidth: false,
          )
        else if (view.canPay && settlement.disbursements.isNotEmpty)
          EteeloButton.secondary(
            label: l10n.payrollAgentPayments,
            icon: Icons.receipt_long_outlined,
            onPressed: () => ledger.openPayout(line, canWrite: canWrite),
            size: EteeloButtonSize.regular,
            fullWidth: false,
          ),
      ],
    );
  }
}

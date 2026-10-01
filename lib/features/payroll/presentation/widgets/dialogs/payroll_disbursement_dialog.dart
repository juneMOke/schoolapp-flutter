import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un versement enregistré, en lecture : mode, preuve, date, état d'envoi.
/// L'économe peut l'annuler — rend `true` pour ouvrir l'annulation.
class PayrollDisbursementDialog extends StatelessWidget {
  final String name;
  final PayrollDisbursement disbursement;
  final bool canCancel;

  const PayrollDisbursementDialog({
    super.key,
    required this.name,
    required this.disbursement,
    required this.canCancel,
  });

  static Future<bool> show(
    BuildContext context,
    PayrollDisbursementDialog dialog,
  ) async => await EteeloFormDialog.show<bool>(context, dialog) ?? false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = disbursement;
    final rows = <(String, String)>[
      (l10n.payrollPayNet, MoneyFormat.format(d.amount)),
      (l10n.payrollColPayout, PayrollLabels.mode(l10n, d.mode)),
      if (d.mode == PayoutMode.mobileMoney) ...[
        if (d.operator != null)
          (
            l10n.payrollProfileOperator,
            PayrollLabels.operator(l10n, d.operator!),
          ),
        (l10n.payrollPayPhone, d.payoutPhone ?? '—'),
        (l10n.payrollPayReference, d.reference ?? '—'),
      ],
      if (d.mode == PayoutMode.bank) ...[
        (l10n.payrollPayBankName, d.bankName ?? '—'),
        (l10n.payrollPayBankReference, d.reference ?? '—'),
      ],
      if (d.mode == PayoutMode.cash && d.signedRegister)
        (l10n.payrollModeCash, l10n.payrollPaySigned),
    ];
    return EteeloFormDialog(
      eyebrow: name,
      title: l10n.payrollPaidOn(PayrollLabels.day(context, d.paidAt)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: AppTypography.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: RecordSyncPill(state: d.syncState),
          ),
        ],
      ),
      leading: canCancel
          ? EteeloButton.ghost(
              label: l10n.payrollPayCancel,
              icon: Icons.undo,
              onPressed: () => Navigator.of(context).pop(true),
              fullWidth: false,
            )
          : null,
      actions: [
        EteeloButton.secondary(
          label: l10n.payrollClose,
          onPressed: () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
      ],
    );
  }
}

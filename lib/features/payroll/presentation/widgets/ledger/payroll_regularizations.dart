import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_reason_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les versements refusés, tous mois confondus : l'argent est parti, le
/// serveur ne l'a pas enregistré. Rien n'est effacé — l'économe clôt une
/// ligne, avec motif, une fois la situation réglée avec la direction.
class PayrollRegularizations extends StatelessWidget {
  final List<PayrollDisbursement> disbursements;
  final bool canWrite;

  const PayrollRegularizations({
    super.key,
    required this.disbursements,
    required this.canWrite,
  });

  @override
  Widget build(BuildContext context) {
    if (disbursements.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final actions = PayrollLedgerActions(context);
    final tone = PayrollTone.alert;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: tone.color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.payrollRegularizeTitle,
            style: AppTypography.titleSmall.copyWith(color: tone.ink),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.payrollRegularizeHint,
            style: AppTypography.bodySmall.copyWith(color: tone.ink),
          ),
          for (final disbursement in disbursements)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.payrollRegularizeRow(
                        actions.nameOf(disbursement.staffMemberId),
                        MoneyFormat.format(disbursement.amount),
                        PayrollLabels.month(context, disbursement.month),
                        PayrollLabels.refusal(l10n, disbursement.syncErrorCode),
                      ),
                      style: AppTypography.bodyMedium.copyWith(color: tone.ink),
                    ),
                  ),
                  if (canWrite)
                    EteeloButton.ghost(
                      label: l10n.payrollPayCancel,
                      onPressed: () => _close(context, disbursement),
                      fullWidth: false,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _close(
    BuildContext context,
    PayrollDisbursement disbursement,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await PayrollReasonDialog.show(
      context,
      title: l10n.payrollPayCancel,
      confirmLabel: l10n.payrollPayCancel,
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    await context.read<PayrollCubit>().perform(
      (commands) => commands.cancelDisbursement(disbursement, reason),
    );
  }
}

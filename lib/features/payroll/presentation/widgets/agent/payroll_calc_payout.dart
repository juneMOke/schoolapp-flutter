import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_settlement_band.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_tranche_list.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le versement d'un mois : le taux du mois (ou le montant fixe) et ce qu'il
/// laisse en arriéré ; après validation, le solde progressif et les
/// versements reçus.
class PayrollCalcPayout extends StatelessWidget {
  final PayrollAgentMonth month;

  const PayrollCalcPayout({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = month.line;
    final payout = line.payout;
    String money(int cents) => PayrollLabels.money(cents, line.currency);
    final percent = payout?.ratePercent;
    final policy = payout?.fixed ?? false
        ? l10n.payrollCalcFixed
        : percent == null || percent >= 100
        ? l10n.payrollCalcRateFull
        : l10n.payrollCalcRate(percent);
    final reason = payout?.reason;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textMutedAa,
    );
    final settlement = month.settlement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayrollAmountRow(policy, money(line.toPayInCents)),
        if (reason != null && reason.trim().isNotEmpty)
          Text(reason, style: muted),
        if (line.deferredInCents > 0)
          PayrollAmountRow(
            l10n.payrollCalcDeferred,
            money(line.deferredInCents),
            ink: PayrollTone.submitted.ink,
          ),
        const SizedBox(height: AppSpacing.md),
        if (month.view.canPay) ...[
          PayrollSettlementBand(settlement: settlement),
          if (settlement.disbursements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            PayrollTrancheList(
              disbursements: settlement.disbursements,
              onOpen: (_) => PayrollLedgerActions(context).openPayout(
                line,
                canWrite: PermissionGate.allows(
                  context,
                  kPayrollWriteAccess.requires,
                ),
              ),
            ),
          ],
        ] else
          PayrollTone.draft.notice(
            l10n.payrollCalcAfterValidation,
            icon: Icons.lock_clock_outlined,
          ),
      ],
    );
  }
}

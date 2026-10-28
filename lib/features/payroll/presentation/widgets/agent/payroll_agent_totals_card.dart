import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cumuls de l'année civile, sur les mois validés (montants figés) : de
/// quoi répondre à une attestation de revenus ou à une contestation sans
/// export. Une colonne de chiffres par devise.
class PayrollAgentTotalsCard extends StatelessWidget {
  final String year;
  final List<PayrollAgentTotals> totals;

  const PayrollAgentTotalsCard({
    super.key,
    required this.year,
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final withheld = PayrollTone.alert.ink;
    return EteeloPanelCard(
      title: l10n.payrollAgentTotalsTitle(year),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, t) in totals.indexed) ...[
            if (index > 0) const Divider(height: AppSpacing.lg),
            ..._rows(l10n, t, withheld),
            Text(
              l10n.payrollAgentTotalsMonths(t.months),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _rows(
    AppLocalizations l10n,
    PayrollAgentTotals t,
    Color withheld,
  ) {
    String money(int cents) => PayrollLabels.money(cents, t.currency);
    String minus(int cents) => cents == 0 ? money(0) : '− ${money(cents)}';
    Color? ink(int cents) => cents == 0 ? null : withheld;
    return [
      PayrollAmountRow(l10n.payrollAgentTotalsGross, money(t.grossInCents)),
      PayrollAmountRow(
        l10n.payrollAgentTotalsIprCnss,
        minus(t.iprCnssInCents),
        ink: ink(t.iprCnssInCents),
      ),
      PayrollAmountRow(
        l10n.payrollAgentTotalsAbsence,
        minus(t.absenceInCents),
        ink: ink(t.absenceInCents),
      ),
      PayrollAmountRow(
        l10n.payrollAgentTotalsChildcare,
        minus(t.childcareInCents),
        ink: ink(t.childcareInCents),
      ),
      PayrollAmountRow(
        l10n.payrollAgentTotalsAdvances,
        minus(t.advancesInCents),
        ink: ink(t.advancesInCents),
      ),
      const Divider(height: AppSpacing.md),
      PayrollAmountRow(l10n.payrollAgentTotalsNet, money(t.netInCents)),
      PayrollAmountRow(l10n.payrollAgentTotalsPaid, money(t.paidInCents)),
    ];
  }
}

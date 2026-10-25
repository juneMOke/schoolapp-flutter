import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_table.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_tiles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les mois dus d'un agent, le plus ancien d'abord : mois et ancienneté,
/// origine, ce qui était dû et ce qui a été versé, le motif d'un versement
/// réduit, le reste — et ce que le versement en cours y imputerait.
class PayrollArrearsMonths extends StatelessWidget {
  final PayrollArrearsAgent agent;
  final String currentMonth;

  /// La répartition du versement saisi : `(mois, montant imputé)`.
  final List<(PayrollArrear, int)> split;

  const PayrollArrearsMonths({
    super.key,
    required this.agent,
    required this.currentMonth,
    required this.split,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imputed = {for (final (arrear, cents) in split) arrear.month: cents};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final arrear in agent.months)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.payrollArrearsSince(
                          PayrollLabels.month(context, arrear.month),
                          PayrollArrearsTiles.monthsBetween(
                            arrear.month,
                            currentMonth,
                          ),
                        ),
                        style: AppTypography.labelLarge,
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          PayrollArrearOriginTag(origin: arrear.origin),
                          if (arrear.prioritized)
                            Text(
                              l10n.payrollArrearsPriority,
                              style: AppTypography.labelSmall.copyWith(
                                color: PayrollTone.alert.ink,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _detail(l10n, arrear),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PayrollLabels.money(arrear.dueInCents, arrear.currency),
                      style: AppTypography.labelLarge.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (imputed[arrear.month] case final cents?)
                      Text(
                        '− ${PayrollLabels.money(cents, arrear.currency)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: PayrollTone.paid.ink,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _detail(AppLocalizations l10n, PayrollArrear arrear) {
    String money(int cents) => PayrollLabels.money(cents, arrear.currency);
    final base = l10n.payrollArrearsNetPaid(
      money(arrear.line.netInCents),
      money(arrear.paidInCents),
    );
    final payout = arrear.line.payout;
    final reason = arrear.reason;
    final why = payout == null || !payout.isReduced
        ? null
        : payout.fixed
        ? l10n.payrollArrearsFixed(money(payout.toPayInCents))
        : l10n.payrollArrearsRate(payout.ratePercent ?? 100);
    return [
      base,
      ?why,
      if (reason != null && reason.isNotEmpty) reason,
    ].join(' · ');
  }
}

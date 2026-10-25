import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Arriérés par salarié » (spec TB 2) : le reste dû sur les paies validées,
/// groupé par agent, le plus lourd d'abord, une puce par mois d'origine.
class PayrollDashboardArrearsCard extends StatelessWidget {
  final PayrollSnapshot snapshot;
  final List<PayrollArrearsAgent> agents;

  /// La devise du tableau de bord : le classement se fait dans celle-ci —
  /// des centimes de francs et de dollars ne s'additionnent pas.
  final String currency;
  final VoidCallback onSettle;

  const PayrollDashboardArrearsCard({
    super.key,
    required this.snapshot,
    required this.agents,
    required this.currency,
    required this.onSettle,
  });

  int _due(PayrollArrearsAgent agent) => agent.months
      .where((arrear) => arrear.currency == currency)
      .fold(0, (sum, arrear) => sum + arrear.dueInCents);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...agents]..sort((a, b) => _due(b).compareTo(_due(a)));
    return PayrollDashboardCard(
      title: l10n.payrollDashArrearsTitle,
      trailing: sorted.isEmpty
          ? null
          : EteeloButton.ghost(
              label: l10n.payrollDashSettle,
              icon: Icons.arrow_forward,
              onPressed: onSettle,
              fullWidth: false,
            ),
      child: sorted.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.payrollDashArrearsEmpty,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final agent in sorted) _row(context, agent)],
            ),
    );
  }

  Widget _row(BuildContext context, PayrollArrearsAgent agent) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PayrollTone.submitted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  snapshot.member(agent.staffMemberId)?.fullName ??
                      agent.staffMemberId,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  PayrollLabels.perCurrency(
                    agent.months.map((a) => (a.dueInCents, a.currency)),
                  ).join(' · '),
                  textAlign: TextAlign.end,
                  style: AppTypography.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final arrear in agent.months)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tone.soft,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      [
                        PayrollLabels.month(context, arrear.month),
                        PayrollLabels.money(arrear.dueInCents, arrear.currency),
                        if (arrear.prioritized) l10n.payrollDashPriority,
                      ].join(' · '),
                      style: AppTypography.labelSmall.copyWith(color: tone.ink),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

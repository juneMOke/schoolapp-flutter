import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Arriérés par salarié » : le reste dû sur les paies validées, servi par
/// le serveur à l'instant du calcul, le plus lourd d'abord dans la devise
/// affichée, une puce par mois d'origine.
class PayrollDashboardArrearsCard extends StatelessWidget {
  final List<PayrollDashboardArrears> arrears;
  final String currency;
  final VoidCallback onSettle;

  const PayrollDashboardArrearsCard({
    super.key,
    required this.arrears,
    required this.currency,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [
      for (final agent in arrears)
        if (agent.dues.isNotEmpty) agent,
    ]..sort((a, b) => b.dueIn(currency).compareTo(a.dueIn(currency)));
    return EteeloStatsCard(
      title: l10n.payrollDashArrearsTitle,
      icon: Icons.account_balance_outlined,
      tone: DashboardSense.manquant,
      toneStrength: DashboardTones.forceDe(DashboardSense.manquant),
      actions: [
        if (sorted.isNotEmpty)
          EteeloButton.ghost(
            label: l10n.payrollDashSettle,
            icon: Icons.arrow_forward,
            onPressed: onSettle,
            fullWidth: false,
          ),
      ],
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

  Widget _row(BuildContext context, PayrollDashboardArrears agent) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PayrollTone.alert;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  agent.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  PayrollLabels.perCurrency(
                    agent.dues.map((due) => (due.dueInCents, due.currency)),
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
              for (final due in agent.dues)
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
                        PayrollLabels.month(context, due.month),
                        PayrollLabels.money(due.dueInCents, due.currency),
                        if (due.prioritized) l10n.payrollDashPriority,
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

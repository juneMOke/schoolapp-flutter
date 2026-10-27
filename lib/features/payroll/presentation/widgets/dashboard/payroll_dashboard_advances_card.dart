import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Prêts & avances » : qui rembourse, ce qui reste dû, ce que le mois
/// retient — servis par le serveur à l'instant du calcul. Le détail se gère
/// dans Avances & prêts.
class PayrollDashboardAdvancesCard extends StatefulWidget {
  final List<PayrollDashboardAdvance> advances;
  final VoidCallback onManage;

  const PayrollDashboardAdvancesCard({
    super.key,
    required this.advances,
    required this.onManage,
  });

  @override
  State<PayrollDashboardAdvancesCard> createState() => _AdvancesCardState();
}

class _AdvancesCardState extends State<PayrollDashboardAdvancesCard> {
  static const _filters = [
    PayrollAdvanceFilter.ongoing,
    PayrollAdvanceFilter.settled,
    PayrollAdvanceFilter.all,
  ];
  PayrollAdvanceFilter _filter = PayrollAdvanceFilter.ongoing;

  /// Une carte, pas un registre.
  static const int _maxRows = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final advances = widget.advances;
    final ongoing = advances.where((a) => a.phase.isOngoing).toList();
    final visible = [
      for (final advance in advances)
        if (switch (_filter) {
          PayrollAdvanceFilter.ongoing => advance.phase.isOngoing,
          PayrollAdvanceFilter.settled =>
            advance.phase == PayrollAdvancePhase.settled,
          _ => true,
        })
          advance,
    ];
    final due = PayrollLabels.perCurrency(
      ongoing.map((a) => (a.remainingInCents, a.currency)),
    ).join(' · ');
    return EteeloStatsCard(
      title: l10n.payrollDashAdvancesTitle,
      subtitle: ongoing.isEmpty
          ? null
          : l10n.payrollDashAdvancesSubtitle(
              {for (final a in ongoing) a.staffMemberId}.length,
              due,
            ),
      icon: Icons.handshake_outlined,
      tone: DashboardSense.attente,
      toneStrength: DashboardTones.forceDe(DashboardSense.attente),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollDashManage,
          icon: Icons.arrow_forward,
          onPressed: widget.onManage,
          fullWidth: false,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayrollChoiceChips<PayrollAdvanceFilter>(
            values: _filters,
            selected: _filter,
            label: (filter) => switch (filter) {
              PayrollAdvanceFilter.ongoing => l10n.payrollDashFilterOngoing,
              PayrollAdvanceFilter.settled => l10n.payrollDashFilterSettled,
              _ => l10n.payrollAdvancesFilterAll,
            },
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.payrollDashAdvancesEmpty,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else ...[
            for (final advance in visible.take(_maxRows))
              _AdvanceRow(advance: advance),
            if (visible.length > _maxRows)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.payrollDashMore(visible.length - _maxRows),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AdvanceRow extends StatelessWidget {
  final PayrollDashboardAdvance advance;

  const _AdvanceRow({required this.advance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, advance.currency);
    final repaid = advance.repaidShare;
    final details = [
      advance.installments > 1
          ? l10n.payrollAdvanceOver(advance.installments)
          : l10n.payrollAdvanceOnce,
      if (advance.reason case final reason?) PayrollLabels.reason(l10n, reason),
      PayrollLabels.day(context, advance.grantedOn),
      if (advance.takenThisMonthInCents > 0)
        l10n.payrollDashTakenThisMonth(money(advance.takenThisMonthInCents)),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  advance.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.payrollDashRemainingOf(
                    money(advance.remainingInCents),
                    money(advance.amountInCents),
                  ),
                  textAlign: TextAlign.end,
                  style: AppTypography.labelMedium,
                ),
              ),
            ],
          ),
          Text(
            details,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: repaid,
              minHeight: AppDimensions.payrollProgressHeight,
              backgroundColor: AppColors.surfaceAlt,
              color: repaid >= 1
                  ? DashboardSense.encaisse
                  : DashboardSense.attente,
              semanticsLabel: l10n.payrollDashRepaidA11y(
                (repaid * 100).round(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

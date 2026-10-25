import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Prêts & avances » (spec TB 2) : qui rembourse, ce qui reste dû, ce que
/// le mois retient — le détail se gère dans Avances & prêts.
class PayrollDashboardAdvancesCard extends StatefulWidget {
  final PayrollSnapshot snapshot;
  final PayrollMonthView view;
  final VoidCallback onManage;

  const PayrollDashboardAdvancesCard({
    super.key,
    required this.snapshot,
    required this.view,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final advances = widget.snapshot.advances;
    final ongoing = advances.where((a) => a.isOngoing).toList();
    final visible = [
      for (final advance in advances)
        if (switch (_filter) {
          PayrollAdvanceFilter.ongoing => advance.isOngoing,
          PayrollAdvanceFilter.settled => advance.isSettled,
          _ => true,
        })
          advance,
    ];
    final due = PayrollLabels.perCurrency(
      ongoing.map((a) => (a.remainingInCents, a.amount.currency)),
    ).join(' · ');
    return PayrollDashboardCard(
      title: l10n.payrollDashAdvancesTitle,
      subtitle: ongoing.isEmpty
          ? null
          : l10n.payrollDashAdvancesSubtitle(
              {for (final a in ongoing) a.staffMemberId}.length,
              due,
            ),
      trailing: EteeloButton.ghost(
        label: l10n.payrollDashManage,
        icon: Icons.arrow_forward,
        onPressed: widget.onManage,
        fullWidth: false,
      ),
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
          else
            for (final advance in visible) _row(context, advance),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, SalaryAdvance advance) {
    final l10n = AppLocalizations.of(context)!;
    final currency = advance.amount.currency;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final amount = advance.amount.amountInCents;
    final repaid = amount == 0
        ? 0.0
        : (amount - advance.remainingInCents) / amount;
    final takenThisMonth = [
      for (final line in widget.view.lines)
        for (final part in line.advances)
          if (part.advanceId == advance.id) part.takenInCents,
    ].fold(0, (sum, cents) => sum + cents);
    final details = [
      advance.installments > 1
          ? l10n.payrollAdvanceOver(advance.installments)
          : l10n.payrollAdvanceOnce,
      PayrollLabels.reason(l10n, advance.reason),
      PayrollLabels.day(context, advance.grantedOn),
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
                  widget.snapshot.member(advance.staffMemberId)?.fullName ??
                      advance.staffMemberId,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
              ),
              Text(
                l10n.payrollDashRemainingOf(
                  money(advance.remainingInCents),
                  money(amount),
                ),
                style: AppTypography.labelMedium,
              ),
            ],
          ),
          Text(
            takenThisMonth > 0
                ? '$details · ${l10n.payrollDashTakenThisMonth(money(takenThisMonth))}'
                : details,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: repaid.clamp(0, 1),
              minHeight: AppDimensions.payrollProgressHeight,
              backgroundColor: AppColors.surfaceAlt,
              color: repaid >= 1 ? AppColors.vertSavane : AppColors.orDoux,
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

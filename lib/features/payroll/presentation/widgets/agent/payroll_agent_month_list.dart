import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_settlement_pill.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les fiches de paie de l'agent, une par mois tenu, la plus récente en
/// tête — l'historique, mais pour cet agent. Toucher un mois l'affiche à
/// côté ; le mois affiché est cerné à la marque, comme dans la frise.
class PayrollAgentMonthList extends StatelessWidget {
  final List<PayrollAgentMonth> months;
  final String selected;
  final ValueChanged<String> onSelect;

  const PayrollAgentMonthList({
    super.key,
    required this.months,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloPanelCard(
      title: l10n.payrollAgentMonths(months.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, month) in months.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            _MonthTile(
              month: month,
              selected: month.month == selected,
              onTap: () => onSelect(month.month),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final PayrollAgentMonth month;
  final bool selected;
  final VoidCallback onTap;

  const _MonthTile({
    required this.month,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = month.line;
    final settlement = month.settlement;
    final label = PayrollLabels.month(context, month.month);
    final detail = month.isLocked
        ? l10n.payrollAgentMonthPaid(
            PayrollLabels.money(settlement.paidInCents, line.currency),
          )
        : PayrollLabels.phase(l10n, month.phase);
    final border = selected ? PayrollTone.current.color : AppColors.border;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.stateHover : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(
            color: border,
            width: selected ? AppSpacing.xs / 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.payrollAgentMonthTileMin,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label[0].toUpperCase() + label.substring(1),
                          style: AppTypography.titleSmall,
                        ),
                        Text(
                          detail,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMutedAa,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          PayrollLabels.money(line.netInCents, line.currency),
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs / 2),
                        if (month.isLocked)
                          PayrollSettlementPill(status: settlement.status)
                        else
                          PayrollStatusPill(phase: month.phase),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

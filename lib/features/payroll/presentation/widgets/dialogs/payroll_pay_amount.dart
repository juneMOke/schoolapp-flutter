import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le montant d'un versement (B3) : prérempli à ce qui reste de la part
/// prévue ce mois, avec des raccourcis, et ce qu'il laissera dû. Il ne
/// dépasse jamais le reste ; au-delà de la part prévue, un avertissement
/// seulement (T8).
class PayrollPayAmount extends StatelessWidget {
  final PayrollSettlement settlement;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const PayrollPayAmount({
    super.key,
    required this.settlement,
    required this.controller,
    required this.onChanged,
  });

  /// Le montant proposé à l'ouverture.
  static int initialOf(PayrollSettlement settlement) =>
      settlement.plannedRemainingInCents > 0
      ? settlement.plannedRemainingInCents
      : settlement.remainingInCents;

  static String format(int cents, String currency) =>
      MoneyFormat.amountOnly(Money(cents, currency));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = settlement.line.currency;
    final remaining = settlement.remainingInCents;
    final net = settlement.netInCents;
    final typed = AmountInput.toCents(controller.text);
    final shortcuts = <(String, int)>[
      if (settlement.line.deferredInCents > 0 &&
          settlement.plannedRemainingInCents > 0)
        (l10n.payrollPayPlanned, settlement.plannedRemainingInCents),
      (l10n.payrollPayAllRemaining, remaining),
      for (final share in const [50, 30])
        if (PayrollMath.roundDiv(net * share, 100) case final cents
            when cents > 0 && cents < remaining)
          (l10n.payrollPayShare(share), cents),
    ];
    void pick(int cents) {
      controller.text = format(cents, currency);
      onChanged();
    }

    final String? help;
    final Color ink;
    if (typed == null || typed <= 0 || typed > remaining) {
      help = null;
      ink = AppColors.textSecondary;
    } else if (typed == remaining) {
      help = l10n.payrollPaySettles;
      ink = PayrollTone.paid.ink;
    } else {
      help = l10n.payrollPayLeaves(
        PayrollLabels.money(remaining - typed, currency),
      );
      ink = PayrollTone.submitted.ink;
    }
    final abovePlan =
        typed != null &&
        settlement.line.deferredInCents > 0 &&
        typed > settlement.plannedRemainingInCents &&
        typed <= remaining;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EteeloTextInput(
          controller: controller,
          label: l10n.payrollPayAmount(currency),
          required: true,
          keyboardType: EteeloTextInputType.number,
          capitalization: EteeloTextCapitalization.none,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (label, cents) in shortcuts)
              EteeloFilterChip(
                label: label,
                selected: typed == cents,
                color: AppColors.terreCuite,
                soft: AppColors.terreCuiteSoft,
                ink: AppColors.terreCuiteDark,
                onTap: () => pick(cents),
              ),
          ],
        ),
        if (help != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(help, style: AppTypography.bodySmall.copyWith(color: ink)),
        ],
        if (abovePlan) ...[
          const SizedBox(height: AppSpacing.xs),
          PayrollTone.submitted.notice(
            l10n.payrollPayAbovePlan,
            icon: Icons.warning_amber_rounded,
          ),
        ],
      ],
    );
  }
}

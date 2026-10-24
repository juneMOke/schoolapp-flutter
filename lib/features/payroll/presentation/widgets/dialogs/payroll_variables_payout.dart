import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le versement de ce mois pour l'agent : le taux du mois (défaut), ou un
/// montant fixe qui prime, avec son motif. Le net dû ne change pas ; ce qui
/// n'est pas versé devient un arriéré à la validation.
class PayrollVariablesPayout extends StatelessWidget {
  final PayrollLine preview;

  /// Le taux du mois, en %.
  final int monthRate;
  final bool fixed;
  final TextEditingController amount;
  final TextEditingController reason;
  final ValueChanged<bool> onFixed;
  final VoidCallback onChanged;

  const PayrollVariablesPayout({
    super.key,
    required this.preview,
    required this.monthRate,
    required this.fixed,
    required this.amount,
    required this.reason,
    required this.onFixed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, preview.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.payrollVarsPayout, style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SegmentedTabFilter<bool>(
          expand: true,
          selected: fixed,
          onSelected: onFixed,
          options: [
            SegmentedTabOption(
              label: l10n.payrollVarsPayoutRate(monthRate),
              value: false,
            ),
            SegmentedTabOption(label: l10n.payrollVarsPayoutFixed, value: true),
          ],
        ),
        if (fixed) ...[
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: amount,
            label: l10n.payrollVarsFixedAmount,
            required: true,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: reason,
            label: l10n.payrollVarsFixedReason,
            required: true,
            capitalization: EteeloTextCapitalization.sentence,
            onChanged: (_) => onChanged(),
          ),
        ],
        if (preview.deferredInCents > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          PayrollTone.submitted.notice(
            l10n.payrollVarsPayoutPreview(
              money(preview.toPayInCents),
              money(preview.deferredInCents),
            ),
            icon: Icons.hourglass_bottom,
          ),
        ],
      ],
    );
  }
}

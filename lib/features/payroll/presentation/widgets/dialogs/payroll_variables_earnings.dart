import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gains variables d'un agent : heures supplémentaires et leur taux,
/// enfants à charge et leurs allocations.
class PayrollVariablesEarnings extends StatelessWidget {
  final PayrollLine line;
  final PayrollLine preview;
  final int overtime;
  final int children;
  final TextEditingController rate;
  final int childUnitInCents;
  final ValueChanged<int> onOvertime;
  final ValueChanged<int> onChildren;
  final VoidCallback onChanged;

  const PayrollVariablesEarnings({
    super.key,
    required this.line,
    required this.preview,
    required this.overtime,
    required this.children,
    required this.rate,
    required this.childUnitInCents,
    required this.onOvertime,
    required this.onChildren,
    required this.onChanged,
  });

  static const int _halfHour = 30;
  static const int _maxChildren = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, line.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.payrollVarsOvertime, style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        if (!line.overtimeAllowed)
          PayrollTone.draft.notice(l10n.payrollVarsNoOvertime)
        else ...[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PayrollStepper(
                value: overtime,
                step: _halfHour,
                format: (minutes) => PayrollLabels.hours(l10n, minutes),
                decreaseLabel: l10n.payrollDecrease,
                increaseLabel: l10n.payrollIncrease,
                onChanged: (value) => onOvertime(value),
              ),
              Text(
                money(preview.overtimeInCents),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: rate,
            label: l10n.payrollVarsRate,
            placeholder: l10n.payrollVarsRateHint(
              money(preview.overtimeRateInCents),
            ),
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            onChanged: (_) => onChanged(),
          ),
        ],
        const Divider(),
        Text(l10n.payrollVarsChildren, style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PayrollStepper(
              value: children,
              max: _maxChildren,
              format: (value) => '$value',
              decreaseLabel: l10n.payrollDecrease,
              increaseLabel: l10n.payrollIncrease,
              onChanged: (value) => onChildren(value),
            ),
            Text(
              l10n.payrollVarsAllowance(
                children,
                money(childUnitInCents),
                money(preview.allowanceInCents),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

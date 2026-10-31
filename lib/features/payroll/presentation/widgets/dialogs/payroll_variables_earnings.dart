import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gains d'un agent : sa base, ses heures supplémentaires et leur taux, ses
/// enfants à charge. Rien pour ce qui ne le concerne pas : ni heures pour un
/// vacataire, ni enfants sans allocation réglée, ni taux sans heures.
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
    final showsChildren = childUnitInCents > 0 || children > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PayrollAmountRow(l10n.payrollVarsBase, money(preview.baseInCents)),
        if (line.overtimeAllowed) ...[
          const SizedBox(height: AppSpacing.sm),
          _StepperRow(
            label: l10n.payrollVarsOvertime,
            note: overtime > 0 ? money(preview.overtimeInCents) : null,
            stepper: PayrollStepper(
              value: overtime,
              step: _halfHour,
              format: (minutes) => PayrollLabels.hours(l10n, minutes),
              decreaseLabel: l10n.payrollDecrease,
              increaseLabel: l10n.payrollIncrease,
              onChanged: (value) => onOvertime(value),
            ),
          ),
          if (overtime > 0 || rate.text.isNotEmpty) ...[
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
        ],
        if (showsChildren) ...[
          const SizedBox(height: AppSpacing.sm),
          _StepperRow(
            label: l10n.payrollVarsChildren,
            note: children > 0
                ? l10n.payrollVarsAllowance(
                    children,
                    money(childUnitInCents),
                    money(preview.allowanceInCents),
                  )
                : null,
            stepper: PayrollStepper(
              value: children,
              max: _maxChildren,
              format: (value) => '$value',
              decreaseLabel: l10n.payrollDecrease,
              increaseLabel: l10n.payrollIncrease,
              onChanged: (value) => onChildren(value),
            ),
          ),
        ],
      ],
    );
  }
}

/// Un libellé et sa note à gauche, le compteur à droite ; à l'étroit, le
/// compteur passe dessous.
class _StepperRow extends StatelessWidget {
  final String label;
  final String? note;
  final Widget stepper;

  const _StepperRow({
    required this.label,
    required this.note,
    required this.stepper,
  });

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.bodyMedium),
            if (note != null)
              Text(
                note,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        stepper,
      ],
    );
  }
}

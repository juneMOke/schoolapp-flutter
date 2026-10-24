import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les retenues fixes v2 dans les éléments variables : les jours prestés
/// (NJP, pré-remplis par le Pointage de M−1, corrigeables), la prise en
/// charge des enfants (PC/E), et ce qu'elles retiennent sur le brut.
class PayrollVariablesDeductions extends StatelessWidget {
  /// La ligne qu'auraient les éléments saisis.
  final PayrollLine preview;

  /// Les jours prestés que dit le Pointage, sans correction.
  final int? attendanceWorkedDays;
  final TextEditingController childcare;
  final ValueChanged<int> onWorkedDays;
  final VoidCallback onChanged;

  const PayrollVariablesDeductions({
    super.key,
    required this.preview,
    required this.attendanceWorkedDays,
    required this.childcare,
    required this.onWorkedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deductions = preview.deductions;
    final divisor = deductions.workDaysDivisor;
    final worked = deductions.workedDays;
    String money(int cents) => PayrollLabels.money(cents, preview.currency);
    final corrected =
        worked != null &&
        attendanceWorkedDays != null &&
        worked != attendanceWorkedDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (divisor != null && worked != null) ...[
          Text(l10n.payrollVarsWorkedDays, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          PayrollStepper(
            value: worked,
            max: divisor,
            format: (days) => l10n.payrollVarsWorkedDaysValue(days, divisor),
            decreaseLabel: l10n.payrollDecrease,
            increaseLabel: l10n.payrollIncrease,
            onChanged: onWorkedDays,
          ),
          if (corrected) ...[
            const SizedBox(height: AppSpacing.xs),
            PayrollTone.submitted.notice(
              l10n.payrollVarsWorkedDaysCorrected(attendanceWorkedDays!),
              icon: Icons.edit_calendar_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
        EteeloTextInput(
          controller: childcare,
          label: l10n.payrollVarsChildcare,
          keyboardType: EteeloTextInputType.number,
          capitalization: EteeloTextCapitalization.none,
          onChanged: (_) => onChanged(),
        ),
        if (deductions.absenceInCents > 0)
          PayrollAmountRow(
            l10n.payrollVarsAbsence(deductions.absentDays ?? 0),
            '− ${money(deductions.absenceInCents)}',
            ink: AppColors.error,
          ),
        if (deductions.iprInCents + deductions.cnssInCents > 0)
          PayrollAmountRow(
            l10n.payrollVarsLegal,
            '− ${money(deductions.iprInCents + deductions.cnssInCents)}',
            ink: AppColors.error,
          ),
        if (deductions.childcareInCents > 0)
          PayrollAmountRow(
            l10n.payrollVarsChildcareShort,
            '− ${money(deductions.childcareInCents)}',
            ink: AppColors.error,
          ),
      ],
    );
  }
}

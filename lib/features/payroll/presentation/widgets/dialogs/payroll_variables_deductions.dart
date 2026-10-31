import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les retenues du modèle dans les éléments variables : ce qui est calculé, à
/// lire, puis la prise en charge des enfants (PC/E), à saisir. Une retenue à 0
/// ne se montre pas. L'absence ne se saisit pas (formule 3) : elle vient du
/// Pointage clos du mois, qu'on rouvre pour la corriger.
class PayrollVariablesDeductions extends StatelessWidget {
  /// La ligne qu'auraient les éléments saisis.
  final PayrollLine preview;
  final TextEditingController childcare;

  /// Coupée par l'école (Q8), la PC/E ne se saisit pas : elle compterait 0.
  final bool childcareEnabled;
  final VoidCallback onChanged;

  const PayrollVariablesDeductions({
    super.key,
    required this.preview,
    required this.childcare,
    this.childcareEnabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deductions = preview.deductions;
    String money(int cents) => PayrollLabels.money(cents, preview.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        if (preview.advances.isNotEmpty)
          PayrollAmountRow(
            l10n.payrollVarsAdvances,
            '− ${money(preview.advanceInCents)}',
            ink: AppColors.error,
          ),
        if (childcareEnabled)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: EteeloTextInput(
              controller: childcare,
              label: l10n.payrollVarsChildcare,
              keyboardType: EteeloTextInputType.number,
              capitalization: EteeloTextCapitalization.none,
              onChanged: (_) => onChanged(),
            ),
          ),
      ],
    );
  }
}

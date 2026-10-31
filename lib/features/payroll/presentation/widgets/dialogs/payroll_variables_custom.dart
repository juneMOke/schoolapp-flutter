import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_custom_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

export 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_custom_field.dart';

/// Les rubriques de l'école dans les éléments variables : chaque rubrique
/// active de la devise de la ligne, ouverte sur son montant, plus toute autre
/// qui porte encore un montant — il faut pouvoir le retirer.
class PayrollVariablesCustom extends StatelessWidget {
  final List<PayrollCustomField> fields;

  /// La ligne qu'auraient les montants saisis.
  final PayrollLine preview;
  final VoidCallback onChanged;

  const PayrollVariablesCustom({
    super.key,
    required this.fields,
    required this.preview,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.payrollVarsCustomTitle,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _Field(field: field, preview: preview, onChanged: onChanged),
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final PayrollCustomField field;
  final PayrollLine preview;
  final VoidCallback onChanged;

  const _Field({
    required this.field,
    required this.preview,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = preview.currency;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final retained = preview.deductions.custom
        .where((c) => c.deductionTypeId == field.type.id)
        .firstOrNull;
    final foreign = field.foreignEntry;
    final refused = field.refused ? field.entry : null;
    final note = foreign != null
        ? l10n.payrollVarsCustomForeign(
            PayrollLabels.money(foreign.amountInCents, foreign.currency),
          )
        : refused != null
        ? l10n.payrollVarsCustomRefused(
            PayrollLabels.money(refused.amountInCents, refused.currency),
            PayrollLabels.serverRefusal(l10n, refused.syncErrorCode),
          )
        : retained != null && retained.trimmed
        ? l10n.payrollVarsCustomTrimmed(
            money(retained.requestedInCents),
            money(retained.takenInCents),
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (field.locked)
          _LockedRow(field: field, money: money, onChanged: onChanged)
        else
          EteeloTextInput(
            controller: field.controller,
            label: field.type.label,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            errorText: field.invalid ? l10n.payrollRuleInvalidAmount : null,
            onChanged: (_) => onChanged(),
          ),
        if (field.defaultInCents case final amount?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.payrollVarsCustomDefault(money(amount)),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              note,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

/// Une rubrique archivée ou d'une autre devise : son montant se lit, et ne se
/// retire qu'à 0.
class _LockedRow extends StatelessWidget {
  final PayrollCustomField field;
  final String Function(int cents) money;
  final VoidCallback onChanged;

  const _LockedRow({
    required this.field,
    required this.money,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = field.type;
    return Row(
      children: [
        Expanded(
          child: PayrollAmountRow(
            type.archived
                ? l10n.payrollVarsCustomArchived(type.label)
                : l10n.payrollVarsCustomOtherCurrency(
                    type.label,
                    type.currency,
                  ),
            switch (field.foreignEntry) {
              final foreign? => PayrollLabels.money(
                foreign.amountInCents,
                foreign.currency,
              ),
              null => money(field.amountInCents),
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        EteeloButton.ghost(
          label: l10n.payrollVarsCustomClear,
          onPressed: field.clearable
              ? () {
                  field.clear();
                  onChanged();
                }
              : null,
          fullWidth: false,
        ),
      ],
    );
  }
}

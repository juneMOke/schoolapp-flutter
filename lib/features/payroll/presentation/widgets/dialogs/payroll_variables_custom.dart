import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une rubrique dans la modale : son champ, et ce qu'elle portait à l'ouverture.
class PayrollCustomField {
  final PayrollDeductionType type;
  final PayrollDeductionEntry? entry;
  final String currency;
  final TextEditingController controller;

  PayrollCustomField._(this.type, this.entry, this.currency, this.controller);

  factory PayrollCustomField.of(
    PayrollDeductionType type,
    PayrollDeductionEntry? entry,
    String currency,
  ) {
    final counted = entry != null && _sameCurrency(entry, currency);
    final amount = entry?.amountInCents ?? 0;
    return PayrollCustomField._(
      type,
      entry,
      currency,
      TextEditingController(
        text: counted && amount > 0
            ? MoneyFormat.amountOnly(Money(amount, currency))
            : '',
      ),
    );
  }

  static bool _sameCurrency(PayrollDeductionEntry entry, String currency) =>
      CurrencyCode.normalize(entry.currency) ==
      CurrencyCode.normalize(currency);

  /// La saisie porte un montant dans une autre devise que la ligne.
  bool get foreign =>
      entry != null &&
      entry!.amountInCents > 0 &&
      !_sameCurrency(entry!, currency);

  bool get refused => entry?.syncState == RecordSyncState.failed;

  /// Archivée avec un montant : seule la mise à 0 est permise.
  bool get locked => type.archived;

  /// `AmountInput` ne connaît que les montants positifs ; ici, 0 retire la
  /// retenue.
  static final RegExp _zero = RegExp(r'^\s*0*([.,]0*)?\s*$');

  /// Le texte saisi n'est pas un montant.
  bool get invalid =>
      !_zero.hasMatch(controller.text) &&
      AmountInput.toCents(controller.text) == null;

  int get amountInCents => AmountInput.toCents(controller.text) ?? 0;

  /// Ce qui compte tel quel à l'ouverture ; une saisie refusée n'y est plus,
  /// une autre devise non plus.
  int get _openedInCents =>
      entry == null || refused || foreign ? 0 : entry!.amountInCents;

  /// La saisie à écrire, ou `null` si rien n'a changé. Dans une autre devise,
  /// un champ laissé vide ne dit rien ; un 0 tapé efface.
  PayrollDeductionEntry? changed(String staffMemberId) {
    if (invalid) return null;
    final touched = controller.text.trim().isNotEmpty;
    if (amountInCents == _openedInCents && !(foreign && touched)) return null;
    return PayrollDeductionEntry(
      staffMemberId: staffMemberId,
      deductionTypeId: type.id,
      amountInCents: amountInCents,
      currency: currency,
    );
  }

  /// Le montant tel qu'il compterait, pour l'aperçu.
  PayrollDeductionEntry? preview(String staffMemberId) {
    if (amountInCents <= 0) return null;
    return PayrollDeductionEntry(
      staffMemberId: staffMemberId,
      deductionTypeId: type.id,
      amountInCents: amountInCents,
      currency: currency,
    );
  }
}

/// Les rubriques de l'école dans les éléments variables : chaque rubrique
/// active à 0, plus toute archivée qui porte encore un montant — elle compte
/// dans le net, et il faut pouvoir la retirer.
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
    final note = field.foreign
        ? l10n.payrollRuleDeductionCurrency
        : field.refused
        ? PayrollLabels.serverRefusal(l10n, field.entry?.syncErrorCode)
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
          _ArchivedRow(field: field, money: money, onChanged: onChanged)
        else
          EteeloTextInput(
            controller: field.controller,
            label: field.type.label,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            onChanged: (_) => onChanged(),
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

class _ArchivedRow extends StatelessWidget {
  final PayrollCustomField field;
  final String Function(int cents) money;
  final VoidCallback onChanged;

  const _ArchivedRow({
    required this.field,
    required this.money,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: PayrollAmountRow(
            l10n.payrollVarsCustomArchived(field.type.label),
            money(field.amountInCents),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        EteeloButton.ghost(
          label: l10n.payrollVarsCustomClear,
          onPressed: field.amountInCents > 0
              ? () {
                  field.controller.clear();
                  onChanged();
                }
              : null,
          fullWidth: false,
        ),
      ],
    );
  }
}

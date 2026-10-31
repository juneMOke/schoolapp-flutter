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
///
/// Le champ s'ouvre sur **ce qui compte** — la valeur du serveur quand la saisie
/// a été refusée, vide pour une autre devise. Un montant refusé ne se remplit
/// jamais : il repartirait sans geste de l'économe.
class PayrollCustomField {
  final PayrollDeductionType type;
  final PayrollDeductionEntry? entry;
  final String currency;
  final TextEditingController controller;

  /// L'économe a demandé la mise à 0 d'une rubrique verrouillée.
  bool _cleared = false;

  PayrollCustomField._(this.type, this.entry, this.currency, this.controller);

  factory PayrollCustomField.of(
    PayrollDeductionType type,
    PayrollDeductionEntry? entry,
    String currency,
  ) {
    final counted = entry?.counted;
    final amount = counted != null && _sameCurrency(counted, currency)
        ? counted.amountInCents
        : 0;
    return PayrollCustomField._(
      type,
      entry,
      currency,
      TextEditingController(
        text: amount > 0 ? MoneyFormat.amountOnly(Money(amount, currency)) : '',
      ),
    );
  }

  static bool _sameCurrency(PayrollDeductionEntry entry, String currency) =>
      CurrencyCode.normalize(entry.currency) ==
      CurrencyCode.normalize(currency);

  /// Ce qui compte aujourd'hui pour cette rubrique, s'il y a quelque chose.
  PayrollDeductionEntry? get _counted {
    final counted = entry?.counted;
    return counted != null && counted.amountInCents > 0 ? counted : null;
  }

  /// La valeur qui compte est dans une autre devise que la ligne.
  bool get foreign {
    final counted = _counted;
    return counted != null && !_sameCurrency(counted, currency);
  }

  /// Le montant en autre devise, dans sa propre devise.
  PayrollDeductionEntry? get foreignEntry => foreign ? _counted : null;

  bool get refused => entry?.syncState == RecordSyncState.failed;

  /// Archivée : seule la mise à 0 est permise.
  bool get locked => type.archived;

  /// La mise à 0 d'une rubrique verrouillée a encore quelque chose à faire.
  bool get clearable => !_cleared && (foreign || amountInCents > 0);

  void clear() {
    _cleared = true;
    controller.clear();
  }

  /// `AmountInput` ne connaît que les montants positifs ; ici, 0 retire la
  /// retenue.
  static final RegExp _zero = RegExp(r'^\s*0*([.,]0*)?\s*$');

  /// Le texte saisi n'est pas un montant.
  bool get invalid =>
      !_zero.hasMatch(controller.text) &&
      AmountInput.toCents(controller.text) == null;

  int get amountInCents => AmountInput.toCents(controller.text) ?? 0;

  /// Le montant de la ligne à l'ouverture, dans sa devise.
  int get _openedInCents => foreign ? 0 : _counted?.amountInCents ?? 0;

  bool get _touched => _cleared || controller.text.trim().isNotEmpty;

  /// La saisie à écrire, ou `null` si rien n'a changé. Dans une autre devise,
  /// un champ laissé vide ne dit rien ; un 0 tapé efface.
  PayrollDeductionEntry? changed(String staffMemberId) {
    if (invalid) return null;
    if (amountInCents == _openedInCents && !(foreign && _touched)) return null;
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
          _ArchivedRow(field: field, money: money, onChanged: onChanged)
        else
          EteeloTextInput(
            controller: field.controller,
            label: field.type.label,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            errorText: field.invalid ? l10n.payrollRuleInvalidAmount : null,
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

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_custom.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fiche d'une rubrique, à la création ou à la modification : code, libellé,
/// description, devise, montant par défaut. Rend la fiche saisie, ou `null`.
class PayrollDeductionTypeDialog extends StatefulWidget {
  final String title;

  /// Les devises réglées par l'école.
  final List<String> currencies;

  /// La rubrique modifiée ; `null` : une création.
  final PayrollDeductionType? initial;

  /// Rubrique utilisée : son code et sa devise ne changent plus.
  final bool locked;

  const PayrollDeductionTypeDialog({
    super.key,
    required this.title,
    required this.currencies,
    this.initial,
    this.locked = false,
  });

  static Future<PayrollDeductionTypeDraft?> show(
    BuildContext context,
    PayrollDeductionTypeDialog dialog,
  ) => EteeloFormDialog.show<PayrollDeductionTypeDraft>(context, dialog);

  @override
  State<PayrollDeductionTypeDialog> createState() =>
      _PayrollDeductionTypeDialogState();
}

class _PayrollDeductionTypeDialogState
    extends State<PayrollDeductionTypeDialog> {
  late final TextEditingController _code = TextEditingController(
    text: widget.initial?.code ?? '',
  );
  late final TextEditingController _label = TextEditingController(
    text: widget.initial?.label ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: _openingAmount(widget.initial),
  );
  late String? _currency = switch (widget.initial?.currency) {
    final currency? when currency.isNotEmpty => currency,
    _ => widget.currencies.firstOrNull,
  };
  bool _touched = false;

  /// Une rubrique venue d'un serveur antérieur au contrat a un code ou une
  /// devise vides : les remplir reste permis, même si elle a servi.
  bool get _codeLocked =>
      widget.locked && (widget.initial?.code.isNotEmpty ?? false);
  bool get _currencyLocked =>
      widget.locked && (widget.initial?.currency.isNotEmpty ?? false);

  static String _openingAmount(PayrollDeductionType? type) =>
      type == null || type.defaultAmountInCents == 0
      ? '0'
      : MoneyFormat.amountOnly(Money(type.defaultAmountInCents, type.currency));

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  String get _codeValue => _code.text.trim().toUpperCase();
  String get _labelValue => _label.text.trim();
  String get _descriptionValue => _description.text.trim();
  int? get _amountValue => PayrollCustomField.centsOf(_amount.text);

  bool get _codeValid => PayrollDeductionType.codeFormat.hasMatch(_codeValue);

  bool get _labelValid =>
      _labelValue.isNotEmpty &&
      _labelValue.length <= PayrollDeductionType.maxLabelLength;

  bool get _descriptionValid =>
      _descriptionValue.length <= PayrollDeductionType.maxDescriptionLength;

  bool get _valid =>
      _codeValid &&
      _labelValid &&
      _descriptionValid &&
      _currency != null &&
      _amountValue != null;

  String? _labelError(AppLocalizations l10n) {
    if (!_touched || _labelValid) return null;
    return _labelValue.isEmpty
        ? l10n.payrollDeductionsLabelRequired
        : l10n.payrollDeductionsLabelTooLong;
  }

  void _submit() {
    setState(() => _touched = true);
    if (!_valid) return;
    Navigator.of(context).pop(
      PayrollDeductionTypeDraft(
        code: _codeValue,
        label: _labelValue,
        description: _descriptionValue.isEmpty ? null : _descriptionValue,
        currency: _currency!,
        defaultAmountInCents: _amountValue!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const gap = SizedBox(height: AppSpacing.md);
    void edited(String _) => setState(() => _touched = true);
    return EteeloFormDialog(
      onSubmit: _submit,
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.locked) ...[
            Text(
              l10n.payrollDeductionsLockedHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            gap,
          ],
          EteeloTextInput(
            controller: _code,
            label: l10n.payrollDeductionsCode,
            autofocus: widget.initial == null,
            required: true,
            readOnly: _codeLocked,
            capitalization: EteeloTextCapitalization.none,
            errorText: _touched && !_codeValid
                ? l10n.payrollDeductionsCodeInvalid
                : null,
            onChanged: edited,
          ),
          gap,
          EteeloTextInput(
            controller: _label,
            label: l10n.payrollDeductionsLabel,
            required: true,
            errorText: _labelError(l10n),
            onChanged: edited,
          ),
          gap,
          EteeloTextInput(
            controller: _description,
            label: l10n.payrollDeductionsDescription,
            maxLines: 3,
            errorText: _touched && !_descriptionValid
                ? l10n.payrollDeductionsDescriptionTooLong
                : null,
            onChanged: edited,
          ),
          gap,
          EteeloSelectInput<String>(
            label: l10n.payrollDeductionsCurrency,
            required: true,
            readOnly: _currencyLocked,
            value: _currency,
            items: [
              for (final currency in {
                ...widget.currencies,
                ?widget.initial?.currency,
              })
                if (currency.isNotEmpty)
                  EteeloSelectItem(value: currency, label: currency),
            ],
            onChanged: (currency) => setState(() => _currency = currency),
          ),
          gap,
          EteeloTextInput(
            controller: _amount,
            label: l10n.payrollDeductionsDefaultAmount,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            errorText: _amountValue == null
                ? l10n.payrollRuleInvalidAmount
                : null,
            onChanged: edited,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.payrollDeductionsDefaultHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.payrollSave,
          onPressed: _submit,
          fullWidth: false,
        ),
      ],
    );
  }
}

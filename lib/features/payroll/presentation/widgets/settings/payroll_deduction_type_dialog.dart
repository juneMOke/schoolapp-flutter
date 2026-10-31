import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le libellé d'une rubrique, à la création ou au renommage. Rend le libellé
/// saisi, ou `null`.
class PayrollDeductionTypeDialog extends StatefulWidget {
  final String title;
  final String initial;

  const PayrollDeductionTypeDialog({
    super.key,
    required this.title,
    this.initial = '',
  });

  static Future<String?> show(
    BuildContext context,
    PayrollDeductionTypeDialog dialog,
  ) => EteeloFormDialog.show<String>(context, dialog);

  @override
  State<PayrollDeductionTypeDialog> createState() =>
      _PayrollDeductionTypeDialogState();
}

class _PayrollDeductionTypeDialogState
    extends State<PayrollDeductionTypeDialog> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initial,
  );
  bool _touched = false;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  String get _value => _label.text.trim();

  bool get _valid =>
      _value.isNotEmpty && _value.length <= PayrollDeductionType.maxLabelLength;

  String? _error(AppLocalizations l10n) {
    if (!_touched || _valid) return null;
    return _value.isEmpty
        ? l10n.payrollDeductionsLabelRequired
        : l10n.payrollDeductionsLabelTooLong;
  }

  void _submit() {
    setState(() => _touched = true);
    if (_valid) Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloFormDialog(
      onSubmit: _submit,
      title: widget.title,
      body: EteeloTextInput(
        controller: _label,
        label: l10n.payrollDeductionsLabel,
        autofocus: true,
        required: true,
        errorText: _error(l10n),
        onChanged: (_) => setState(() => _touched = true),
        onSubmitted: (_) => _submit(),
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

/// La confirmation d'une suppression, définitive. Rend `true` pour supprimer.
class PayrollDeductionDeleteDialog extends StatelessWidget {
  final String label;

  const PayrollDeductionDeleteDialog({super.key, required this.label});

  static Future<bool> show(BuildContext context, String label) async =>
      await EteeloFormDialog.show<bool>(
        context,
        PayrollDeductionDeleteDialog(label: label),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloFormDialog(
      title: l10n.payrollDeductionsDeleteTitle(label),
      body: Text(
        l10n.payrollDeductionsDeleteBody,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollCancel,
          onPressed: () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.danger(
          label: l10n.payrollDeductionsDelete,
          onPressed: () => Navigator.of(context).pop(true),
          fullWidth: false,
        ),
      ],
    );
  }
}

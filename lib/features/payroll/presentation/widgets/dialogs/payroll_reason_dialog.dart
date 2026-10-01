import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un geste qui exige un motif : renvoyer, rouvrir, annuler un versement ou
/// une avance. Rend le motif saisi, ou `null`.
class PayrollReasonDialog extends StatefulWidget {
  final String title;
  final String? hint;
  final String confirmLabel;
  final bool destructive;

  const PayrollReasonDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.hint,
    this.destructive = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? hint,
    bool destructive = false,
  }) => EteeloFormDialog.show<String>(
    context,
    PayrollReasonDialog(
      title: title,
      confirmLabel: confirmLabel,
      hint: hint,
      destructive: destructive,
    ),
  );

  @override
  State<PayrollReasonDialog> createState() => _PayrollReasonDialogState();
}

class _PayrollReasonDialogState extends State<PayrollReasonDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hint = widget.hint;
    return EteeloFormDialog(
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null) ...[
            Text(
              hint,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          EteeloTextInput(
            controller: _reason,
            label: l10n.payrollReasonLabel,
            keyboardType: EteeloTextInputType.multiline,
            minLines: 4,
            maxLines: 4,
            required: true,
            errorText: _showError ? l10n.payrollRuleReasonRequired : null,
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        widget.destructive
            ? EteeloButton.danger(
                label: widget.confirmLabel,
                onPressed: _confirm,
                fullWidth: false,
              )
            : EteeloButton.primary(
                label: widget.confirmLabel,
                onPressed: _confirm,
                fullWidth: false,
              ),
      ],
    );
  }
}

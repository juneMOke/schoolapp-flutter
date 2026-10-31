import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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

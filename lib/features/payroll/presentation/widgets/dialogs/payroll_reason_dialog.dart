import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_reason_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un geste de la paie qui exige un motif : renvoyer, rouvrir, annuler un
/// versement ou une avance. Rend le motif saisi, ou `null`.
abstract final class PayrollReasonDialog {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? hint,
    bool destructive = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloReasonDialog.show(
      context,
      EteeloReasonDialog(
        title: title,
        confirmLabel: confirmLabel,
        cancelLabel: l10n.payrollCancel,
        fieldLabel: l10n.payrollReasonLabel,
        requiredError: l10n.payrollRuleReasonRequired,
        hint: hint,
        destructive: destructive,
      ),
    );
  }
}

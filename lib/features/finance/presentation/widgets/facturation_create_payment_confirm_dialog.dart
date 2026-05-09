import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Affiche une dialog de confirmation pour l'opération irréversible de paiement.
/// Retourne `true` si l'utilisateur confirme, `false` sinon.
Future<bool> showCreatePaymentConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  return showAppConfirmationDialog(
    context: context,
    title: l10n.facturationCreatePaymentConfirmTitle,
    message: l10n.facturationCreatePaymentConfirmMessage,
    cancelLabel: l10n.facturationCreatePaymentConfirmCancel,
    confirmLabel: l10n.facturationCreatePaymentConfirmValidate,
    isDestructive: true,
    barrierDismissible: false,
  );
}

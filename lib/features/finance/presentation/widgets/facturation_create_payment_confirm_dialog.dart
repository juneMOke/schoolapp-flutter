import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Affiche une dialog de confirmation pour la validation du paiement.
/// Retourne `true` si l'utilisateur confirme, `false` sinon.
Future<bool> showCreatePaymentConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  return showAppConfirmationDialog(
    context: context,
    title: l10n.facturationCreatePaymentConfirmTitle,
    message: l10n.facturationCreatePaymentConfirmMessage,
    cancelLabel: l10n.facturationCreatePaymentConfirmCancel,
    confirmLabel: l10n.facturationCreatePaymentConfirmValidate,
    isDestructive: false,
    headerIcon: Icons.payments_outlined,
    headerIconColor: AppColors.success,
    headerIconBackgroundColor: AppColors.financeDetailSuccessSoft,
    confirmIcon: Icons.check_circle_outline_rounded,
    confirmButtonColor: AppColors.success,
    confirmForegroundColor: AppColors.blancCasse,
    barrierDismissible: false,
  );
}

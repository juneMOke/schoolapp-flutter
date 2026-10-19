import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Abandonner les modifications ? » — la question posée avant de quitter
/// une saisie non enregistrée. [message] dit ce qui serait perdu ; à défaut,
/// la formule générique.
///
/// `true` : l'utilisateur abandonne sa saisie.
Future<bool> confirmDiscardChanges(BuildContext context, {String? message}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppConfirmationDialog(
    context: context,
    title: l10n.discardChangesTitle,
    message: message ?? l10n.discardChangesMessage,
    confirmLabel: l10n.discardChangesConfirm,
    cancelLabel: l10n.discardChangesKeep,
    isDestructive: true,
  );
}

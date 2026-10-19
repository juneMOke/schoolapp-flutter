import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Abandonner les modifications ? » — la même question pour la fiche d'un
/// agent et pour un contrat, que la sortie vienne du bouton ou du navigateur.
Future<bool> confirmStaffDiscard(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppConfirmationDialog(
    context: context,
    title: l10n.staffDiscardTitle,
    message: l10n.staffDiscardMessage,
    confirmLabel: l10n.staffDiscardConfirm,
    cancelLabel: l10n.staffDiscardKeep,
    isDestructive: true,
  );
}

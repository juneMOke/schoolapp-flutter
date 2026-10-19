import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/navigation/discard_changes_confirmation.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Abandonner les modifications ? » — la même question pour la fiche d'un
/// agent et pour un contrat, que la sortie vienne du bouton ou du navigateur.
Future<bool> confirmStaffDiscard(BuildContext context) => confirmDiscardChanges(
  context,
  message: AppLocalizations.of(context)!.staffDiscardMessage,
);

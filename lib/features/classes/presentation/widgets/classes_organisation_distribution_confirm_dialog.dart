import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<bool> showClassesOrganisationDistributionConfirmDialog(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: l10n.classesOrganisationDistributionConfirmTitle,
    message: l10n.classesOrganisationDistributionConfirmMessage,
    confirmLabel: l10n.confirm,
    cancelLabel: l10n.cancel,
  );

  return confirmed;
}

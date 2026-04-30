import 'package:flutter/material.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<bool> showClassesOrganisationDistributionConfirmDialog(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.classesOrganisationDistributionConfirmTitle),
      content: Text(l10n.classesOrganisationDistributionConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

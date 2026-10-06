import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Confirmation d'une publication (spec S6, PubConfirm) : qui la reçoit — par
/// WhatsApp, les parents des élèves de la classe — et exactement ce qui
/// part. Rend `true` si l'utilisateur confirme.
Future<bool> confirmPublication(
  BuildContext context, {
  required PublicationKind kind,
  required int effectif,
  required String classroomName,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final items = switch (kind) {
    PublicationKind.sujet => [
      l10n.publicationConfirmSujetItems,
      l10n.publicationConfirmSujetNote,
    ],
    PublicationKind.corrige => [l10n.publicationConfirmCorrigeItems],
    PublicationKind.notes => [l10n.publicationConfirmNotesItems],
  };
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppConfirmationDialog(
      title: l10n.publicationConfirmTitle,
      message: [
        l10n.publicationConfirmAudience(effectif, classroomName),
        for (final item in items) '✓ $item',
      ].join('\n'),
      confirmLabel: l10n.publicationPublish,
      cancelLabel: l10n.sujetCancel,
      headerIcon: Icons.send_rounded,
      confirmIcon: Icons.send_rounded,
    ),
  );
  return confirmed ?? false;
}

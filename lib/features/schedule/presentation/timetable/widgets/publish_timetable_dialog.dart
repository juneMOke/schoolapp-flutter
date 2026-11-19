import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O4 — publier (R9) : le résumé, les conflits (bloquants), et ce qui retient
/// encore la publication (hors ligne, envois en attente). Rend `true` pour
/// publier ; « Publier » est inactif tant qu'un blocage reste.
class PublishTimetableDialog extends StatelessWidget {
  final int sessions;
  final int teachers;
  final int conflicts;

  /// Des cases refusées par le serveur : elles ne sont pas au brouillon.
  final int rejected;
  final bool online;
  final bool pending;

  const PublishTimetableDialog({
    super.key,
    required this.sessions,
    required this.teachers,
    required this.conflicts,
    this.rejected = 0,
    required this.online,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = conflicts > 0 || rejected > 0 || !online || pending;
    void submit() => Navigator.of(context).pop(true);
    return EteeloFormDialog(
      title: l10n.classTimetablePublishTitle,
      onSubmit: blocked ? null : submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.classTimetablePublishSessions(sessions),
            style: AppTypography.bodyMedium,
          ),
          Text(
            l10n.classTimetablePublishTeachers(teachers),
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (conflicts > 0)
            EteeloNotice.error(l10n.classTimetableConflictsBlocking(conflicts))
          else
            EteeloNotice.warning(l10n.classTimetableNoConflict),
          if (rejected > 0)
            EteeloNotice.error(l10n.classTimetablePublishRejected(rejected)),
          if (!online) EteeloNotice.error(l10n.classTimetablePublishOffline),
          if (pending) EteeloNotice.error(l10n.classTimetablePublishPending),
          Text(
            l10n.classTimetablePublishConsequence,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
      actions: [
        SecondaryButton(
          label: l10n.classTimetableCancel,
          fullWidth: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PrimaryButton(
          label: l10n.classTimetablePublish,
          fullWidth: false,
          onPressed: blocked ? null : submit,
        ),
      ],
    );
  }
}

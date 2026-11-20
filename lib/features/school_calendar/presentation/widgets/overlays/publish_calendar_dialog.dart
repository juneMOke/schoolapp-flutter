import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O5 — publier (CAL-R10) : le décompte, puis ce qui bloque (pas de cadre,
/// hors ligne, envois en attente) ou l'avertissement « à vérifier ». Rend
/// `true` pour publier ; « Publier » est inactif s'il y a un blocage.
class PublishCalendarDialog extends StatelessWidget {
  final String year;
  final int total;
  final int schoolCount;
  final int toVerify;
  final bool hasFramework;
  final bool online;
  final bool pending;

  const PublishCalendarDialog({
    super.key,
    required this.year,
    required this.total,
    required this.schoolCount,
    required this.toVerify,
    required this.hasFramework,
    required this.online,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = !hasFramework || !online || pending;
    return EteeloFormDialog(
      title: l10n.schoolCalendarPublishTitle(year),
      onSubmit: blocked ? null : () => Navigator.of(context).pop(true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.schoolCalendarPublishSummary(total, schoolCount),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (!hasFramework)
            EteeloNotice.error(l10n.schoolCalendarPublishNoFramework(year)),
          if (!online) EteeloNotice.error(l10n.schoolCalendarPublishOffline),
          if (pending) EteeloNotice.error(l10n.schoolCalendarPublishPending),
          if (toVerify > 0)
            EteeloNotice.warning(l10n.schoolCalendarPublishToVerify(toVerify)),
          Text(
            l10n.schoolCalendarPublishConsequence,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
      actions: [
        SecondaryButton(
          label: l10n.schoolCalendarFormCancel,
          fullWidth: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PrimaryButton(
          label: l10n.schoolCalendarPublish,
          fullWidth: false,
          onPressed: blocked ? null : () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class CalendarDialogLine extends StatelessWidget {
  final String title;
  final String detail;

  const CalendarDialogLine(this.title, this.detail, {super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTypography.bodyMedium),
      Text(detail, style: AppTypography.bodySmall),
    ],
  );
}

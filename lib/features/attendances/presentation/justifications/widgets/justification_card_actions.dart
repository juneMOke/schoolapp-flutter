import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied d'une carte : la pièce, puis les deux décisions.
///
/// Refuser n'est jamais bloqué ; accepter l'est quand le serveur l'a refusé
/// (l'élève n'est plus absent, ou le mois est clos). Une décision en route,
/// ou une demande déjà tranchée, ne propose plus rien que la pièce.
class JustificationCardActions extends StatelessWidget {
  final AttendanceJustification justification;

  /// La pièce s'ouvre-t-elle maintenant (en ligne, ou déjà téléchargée) ?
  final bool attachmentAvailable;
  final VoidCallback onOpenAttachment;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const JustificationCardActions({
    super.key,
    required this.justification,
    required this.attachmentAvailable,
    required this.onOpenAttachment,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attachment = justification.attachment;
    final buttons = [
      if (attachment != null)
        EteeloButton.ghost(
          label: attachmentAvailable
              ? l10n.justificationAttachmentOpen
              : l10n.justificationAttachmentOffline,
          icon: Icons.attach_file,
          onPressed: attachmentAvailable ? onOpenAttachment : null,
          fullWidth: false,
        ),
      if (justification.canReject)
        EteeloButton.secondary(
          label: l10n.justificationReject,
          icon: Icons.close,
          onPressed: onReject,
          fullWidth: false,
        ),
      if (justification.canAccept)
        EteeloButton.primary(
          label: l10n.justificationAccept,
          icon: Icons.check,
          onPressed: onAccept,
          fullWidth: false,
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: buttons,
    );
  }
}

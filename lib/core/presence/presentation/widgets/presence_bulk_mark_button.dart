import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_card_dialog.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pointer d'un geste les « à pointer » que le registre affiche : un menu
/// Présents à l'heure · Absents. Le cas courant — presque tout le monde est
/// là — se règle en marquant les exceptions, puis le reste d'un coup.
///
/// Les absents passent par une confirmation : une absence pèse (à justifier,
/// retenue de paie quand l'école l'active).
class PresenceBulkMarkButton extends StatelessWidget {
  /// Les « à pointer » affichés, sous les filtres en cours.
  final int count;

  /// Présent ou absent ; appelé après la confirmation des absents.
  final ValueChanged<PresenceStatus> onMark;

  const PresenceBulkMarkButton({
    super.key,
    required this.count,
    required this.onMark,
  });

  Future<void> _markAbsent(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await EteeloCardDialog.show<bool>(
      context,
      EteeloCardDialog(
        eyebrow: l10n.presenceMarkBulkEyebrow,
        title: l10n.presenceMarkBulkAbsentTitle(count),
        body: PresenceWarning(
          icon: PresenceTone.of(PresenceStatus.absent).icon,
          tone: PresenceStatus.absent,
          message: l10n.presenceMarkBulkAbsentBody,
        ),
        actions: [
          Builder(
            builder: (context) => EteeloButton.secondary(
              label: l10n.presenceMarkCancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          Builder(
            builder: (context) => EteeloButton.primary(
              label: l10n.presenceMarkBulkAbsentConfirm,
              icon: Icons.event_busy,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) onMark(PresenceStatus.absent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(PresenceTone.of(PresenceStatus.present).icon),
          onPressed: () => onMark(PresenceStatus.present),
          child: Text(l10n.presenceMarkBulkPresent),
        ),
        MenuItemButton(
          leadingIcon: Icon(PresenceTone.of(PresenceStatus.absent).icon),
          onPressed: () => unawaited(_markAbsent(context)),
          child: Text(l10n.presenceMarkBulkAbsent),
        ),
      ],
      builder: (context, controller, _) => EteeloButton.secondary(
        label: l10n.presenceMarkBulkLabel(count),
        icon: Icons.checklist,
        fullWidth: false,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_card_tabs.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux vues de la file. Le badge compte ce qui attend vraiment l'école :
/// une décision déjà en route n'y est plus.
class JustificationQueueTabs extends StatelessWidget {
  final JustificationQueueState state;
  final ValueChanged<JustificationQueueFilter> onSelect;

  const JustificationQueueTabs({
    super.key,
    required this.state,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final awaiting = state.awaitingCount;
    return EteeloCardTabs<JustificationQueueFilter>(
      active: state.filter,
      onSelect: onSelect,
      tabs: [
        EteeloCardTab(
          id: JustificationQueueFilter.open,
          icon: Icons.mark_email_unread_outlined,
          title: l10n.justificationTabOpen,
          subtitle: l10n.justificationTabOpenSubtitle,
          badge: awaiting == 0
              ? null
              : PresenceTone.of(
                  PresenceStatus.late,
                ).badge(l10n.justificationTabOpenBadge(awaiting)),
        ),
        EteeloCardTab(
          id: JustificationQueueFilter.decided,
          icon: Icons.task_alt_outlined,
          title: l10n.justificationTabDecided,
          subtitle: l10n.justificationTabDecidedSubtitle,
        ),
      ],
    );
  }
}

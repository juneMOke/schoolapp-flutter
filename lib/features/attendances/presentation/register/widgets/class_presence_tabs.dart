import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_card_tabs.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois onglets de l'appel : le registre du jour, la fiche d'un élève
/// et le récapitulatif du mois.
class ClassPresenceTabs extends StatelessWidget {
  final ClassPresenceState state;
  final ValueChanged<ClassPresenceTab> onSelect;

  const ClassPresenceTabs({
    super.key,
    required this.state,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = state.register;
    final day = state.presenceDay;
    final closed = state.monthData?.closed ?? false;
    final unmarked = register?.count(PresenceStatus.none) ?? 0;
    EteeloTabBadge tone(PresenceStatus status, String label) =>
        PresenceTone.of(status).badge(label);
    return EteeloCardTabs<ClassPresenceTab>(
      active: state.tab,
      onSelect: onSelect,
      tabs: [
        EteeloCardTab(
          id: ClassPresenceTab.register,
          icon: Icons.fact_check_outlined,
          title: l10n.classPresenceTabRegister,
          subtitle: l10n.classPresenceTabRegisterSubtitle(
            register?.marked ?? 0,
            register?.all.length ?? 0,
          ),
          badge: day?.validated ?? false
              ? tone(PresenceStatus.present, l10n.presenceMarkBadgeValidated)
              : unmarked > 0
              ? tone(
                  PresenceStatus.late,
                  l10n.presenceMarkBadgeToMark(unmarked),
                )
              : null,
        ),
        EteeloCardTab(
          id: ClassPresenceTab.studentMonth,
          icon: Icons.person_search_outlined,
          title: l10n.classPresenceTabStudent,
          subtitle: l10n.classPresenceTabStudentSubtitle(
            PresenceLabels.month(
              MaterialLocalizations.of(context),
              state.month,
            ),
          ),
        ),
        EteeloCardTab(
          id: ClassPresenceTab.recap,
          icon: Icons.summarize_outlined,
          title: l10n.classPresenceTabRecap,
          subtitle: closed
              ? l10n.classPresenceTabRecapSubtitleClosed
              : l10n.classPresenceTabRecapSubtitle,
          badge: closed
              ? tone(PresenceStatus.present, l10n.presenceMarkBadgeClosed)
              : tone(PresenceStatus.none, l10n.presenceMarkBadgeToClose),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_card_tabs.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Les trois onglets du Pointage : le registre du jour, la fiche d'un agent et
/// le récapitulatif du mois.
class StaffAttendanceTabs extends StatelessWidget {
  final StaffAttendanceState state;
  final ValueChanged<StaffAttendanceTab> onSelect;

  const StaffAttendanceTabs({
    super.key,
    required this.state,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => PermissionAware(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = state.register;
    final validated = state.snapshot.isDayValidated(state.day);
    final closed = state.snapshot.isMonthClosed(state.month);
    final unmarked = register.count(PresenceStatus.none);
    EteeloTabBadge tone(PresenceStatus status, String label) =>
        PresenceTone.of(status).badge(label);
    return EteeloCardTabs<StaffAttendanceTab>(
      active: state.tab,
      onSelect: onSelect,
      tabs: [
        EteeloCardTab(
          id: StaffAttendanceTab.register,
          icon: Icons.fact_check_outlined,
          title: l10n.staffAttendanceTabRegister,
          subtitle: l10n.staffAttendanceTabRegisterSubtitle(
            register.marked,
            register.all.length,
          ),
          badge: validated
              ? tone(PresenceStatus.present, l10n.presenceMarkBadgeValidated)
              : unmarked > 0
              ? tone(
                  PresenceStatus.late,
                  l10n.presenceMarkBadgeToMark(unmarked),
                )
              : null,
        ),
        EteeloCardTab(
          id: StaffAttendanceTab.agentMonth,
          icon: Icons.person_search_outlined,
          title: l10n.staffAttendanceTabAgent,
          subtitle: l10n.staffAttendanceTabAgentSubtitle(
            PresenceLabels.month(
              MaterialLocalizations.of(context),
              state.month,
            ),
          ),
        ),
        EteeloCardTab(
          id: StaffAttendanceTab.recap,
          icon: Icons.summarize_outlined,
          title: l10n.staffAttendanceTabRecap,
          subtitle: l10n.staffAttendanceTabRecapSubtitle,
          badge: closed
              ? tone(PresenceStatus.present, l10n.presenceMarkBadgeClosed)
              : state.canCloseMonth &&
                    PermissionGate.allowsAccess(
                      context,
                      kStaffAttendanceManageAccess,
                    )
              ? tone(PresenceStatus.none, l10n.presenceMarkBadgeToClose)
              : null,
        ),
      ],
    );
  }
}

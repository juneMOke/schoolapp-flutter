import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_card_tabs.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = state.register;
    final validated = state.snapshot.isDayValidated(state.day);
    final closed = state.snapshot.isMonthClosed(state.month);
    final unmarked = register.count(StaffAttendanceStatus.none);
    StaffTabBadge tone(StaffAttendanceStatus status, String label) =>
        StaffAttendanceTone.of(status).badge(label);
    return StaffCardTabs<StaffAttendanceTab>(
      active: state.tab,
      onSelect: onSelect,
      tabs: [
        StaffCardTab(
          id: StaffAttendanceTab.register,
          icon: Icons.fact_check_outlined,
          title: l10n.staffAttendanceTabRegister,
          subtitle: l10n.staffAttendanceTabRegisterSubtitle(
            register.marked,
            register.all.length,
          ),
          badge: validated
              ? tone(
                  StaffAttendanceStatus.present,
                  l10n.staffAttendanceBadgeValidated,
                )
              : unmarked > 0
              ? tone(
                  StaffAttendanceStatus.late,
                  l10n.staffAttendanceBadgeToMark(unmarked),
                )
              : null,
        ),
        StaffCardTab(
          id: StaffAttendanceTab.agentMonth,
          icon: Icons.person_search_outlined,
          title: l10n.staffAttendanceTabAgent,
          subtitle: l10n.staffAttendanceTabAgentSubtitle(
            StaffAttendanceLabels.month(
              MaterialLocalizations.of(context),
              state.month,
            ),
          ),
        ),
        StaffCardTab(
          id: StaffAttendanceTab.recap,
          icon: Icons.summarize_outlined,
          title: l10n.staffAttendanceTabRecap,
          subtitle: l10n.staffAttendanceTabRecapSubtitle,
          badge: closed
              ? tone(
                  StaffAttendanceStatus.present,
                  l10n.staffAttendanceBadgeClosed,
                )
              : state.canCloseMonth &&
                    PermissionGate.allows(
                      context,
                      kStaffAttendanceManageAccess.requires,
                    )
              ? tone(
                  StaffAttendanceStatus.none,
                  l10n.staffAttendanceBadgeToClose,
                )
              : null,
        ),
      ],
    );
  }
}

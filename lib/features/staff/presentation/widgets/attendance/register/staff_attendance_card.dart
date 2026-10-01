import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_card.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_presence_view.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_hourly_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_actions.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte d'un agent dans la grille du registre : la carte commune, plus le
/// départ et les heures prestées d'un vacataire à l'heure.
class StaffAttendanceCard extends StatelessWidget {
  final StaffDayRow row;
  final StaffAttendanceSettings settings;
  final bool frozen;

  const StaffAttendanceCard({
    super.key,
    required this.row,
    required this.settings,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context) {
    final view = row.presenceView(AppLocalizations.of(context)!);
    final actions = StaffRowActions(context, row, frozen: frozen);
    return PresenceCard(
      row: view,
      actions: actions,
      schedule: settings,
      badge: row.isHourly ? const StaffHourlyBadge() : null,
      timeExtras: [
        StaffDepartureButton(row: view, onTap: actions.editDeparture),
        if (row.isHourly)
          StaffHoursStepper(
            minutes: row.record?.workedMinutes,
            onStep: actions.adjustHours,
          ),
      ],
    );
  }
}

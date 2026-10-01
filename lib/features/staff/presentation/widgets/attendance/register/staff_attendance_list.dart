import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_list_frame.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre en liste : une ligne par agent, et la colonne des heures
/// seulement quand la liste filtrée compte un vacataire à l'heure.
class StaffAttendanceList extends StatelessWidget {
  final StaffDayRegister register;

  const StaffAttendanceList({super.key, required this.register});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showHours = register.showsHours;
    return PresenceListFrame(
      personColumn: l10n.staffAttendanceColAgent,
      timesColumn: l10n.staffAttendanceColTimes,
      hoursColumn: showHours ? l10n.staffAttendanceColHours : null,
      rows: [
        for (final row in register.rows)
          StaffAttendanceRow(
            key: ValueKey(row.member.id),
            row: row,
            frozen: register.frozen,
            showHours: showHours,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row_controls.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_presence_view.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_hourly_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_actions.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne du registre d'un agent : la ligne commune, avec arrivée et
/// départ, et la colonne des heures quand la liste compte un vacataire.
class StaffAttendanceRow extends StatelessWidget {
  final StaffDayRow row;
  final bool frozen;
  final bool showHours;

  const StaffAttendanceRow({
    super.key,
    required this.row,
    required this.frozen,
    required this.showHours,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = row.presenceView(l10n);
    final actions = StaffRowActions(context, row, frozen: frozen);
    return PresenceRow(
      row: view,
      actions: actions,
      badge: row.isHourly ? const StaffHourlyBadge() : null,
      times: Row(
        children: [
          Expanded(
            child: PresenceTimeButton(
              label: l10n.presenceMarkArrival,
              time: view.arrival,
              onTap: actions.editArrival,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: StaffDepartureButton(
              row: view,
              onTap: actions.editDeparture,
            ),
          ),
        ],
      ),
      hours: !showHours
          ? null
          : row.isHourly && row.status.hasArrival
          ? StaffHoursStepper(
              minutes: row.record?.workedMinutes,
              onStep: actions.adjustHours,
            )
          : const SizedBox.shrink(),
    );
  }
}

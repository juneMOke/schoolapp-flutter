import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_row_controls.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// Les contrôles propres au Pointage, ajoutés à ceux du registre commun : le
// départ et les heures prestées d'un vacataire à l'heure.

/// Le bouton du départ d'un agent.
class StaffDepartureButton extends StatelessWidget {
  final PresenceRowView row;
  final VoidCallback onTap;

  const StaffDepartureButton({
    super.key,
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PresenceTimeButton(
    label: AppLocalizations.of(context)!.presenceMarkDeparture,
    time: row.departure,
    onTap: onTap,
  );
}

/// Les heures prestées d'un vacataire à l'heure : − 3 h +, de 0 à 10 h.
class StaffHoursStepper extends StatelessWidget {
  final int? minutes;
  final ValueChanged<int> onStep;

  const StaffHoursStepper({
    super.key,
    required this.minutes,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = minutes ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresenceSquareIconButton(
          icon: Icons.remove,
          tooltip: l10n.staffAttendanceHoursLess,
          onPressed: value <= 0 ? null : () => onStep(-1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            PresenceLabels.hours(l10n, value),
            style: AppTypography.labelLarge,
          ),
        ),
        PresenceSquareIconButton(
          icon: Icons.add,
          tooltip: l10n.staffAttendanceHoursMore,
          onPressed: value >= StaffAttendanceRecord.maxWorkedMinutes
              ? null
              : () => onStep(1),
        ),
      ],
    );
  }
}

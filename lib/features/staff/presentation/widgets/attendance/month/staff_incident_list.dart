import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_status_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';

/// Les retards et absences d'un agent sur le mois : le jour, le statut,
/// l'heure et les minutes, et la justification (vert) ou « Non justifié »
/// (rouge).
class StaffIncidentList extends StatelessWidget {
  final List<StaffAttendanceRecord> incidents;

  const StaffIncidentList({super.key, required this.incidents});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    if (incidents.isEmpty) {
      return Text(
        l10n.presenceMarkNoIncidents,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedAa),
      );
    }
    return Column(
      children: [
        for (final record in incidents)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    PresenceLabels.longDay(dates, record.workDate),
                    style: AppTypography.bodyMedium,
                  ),
                ),
                PresenceStatusPill(status: record.status),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: Text(
                    record.status == PresenceStatus.late
                        ? '${record.arrival?.wire ?? ''} · '
                              '+${l10n.presenceMarkMinutes(record.lateMinutes)}'
                        : '',
                    style: AppTypography.bodySmall,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    record.justification == null
                        ? l10n.presenceMarkUnjustified
                        : StaffAttendanceLabels.reason(
                            l10n,
                            record.justification!.reason,
                          ),
                    style: AppTypography.labelMedium.copyWith(
                      color: record.isJustified
                          ? AppColors.presenceMarkPresentInk
                          : AppColors.presenceMarkAbsentInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

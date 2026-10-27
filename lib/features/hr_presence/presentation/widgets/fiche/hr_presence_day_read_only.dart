import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_status_pill.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le jour tel que la fiche (le serveur) le montre, quand la feuille ne peut
/// pas le corriger : le statut, les heures, le retard, le motif — puis
/// pourquoi, et le registre quand il peut aider.
class HrPresenceDayReadOnly extends StatelessWidget {
  final HrAttendanceDay server;
  final String message;

  /// `null` : le registre n'y peut rien (mois clos, droit manquant).
  final VoidCallback? onOpenRegister;

  const HrPresenceDayReadOnly({
    super.key,
    required this.server,
    required this.message,
    this.onOpenRegister,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final arrival = ClockTime.tryParse(server.arrival);
    final departure = ClockTime.tryParse(server.departure);
    final reason = server.reason;
    final note = server.note?.trim();
    final facts = [
      if (arrival != null) l10n.hrPresenceDayArrival(arrival.wire),
      if (departure != null) l10n.hrPresenceDayDeparture(departure.wire),
      if (server.status == PresenceStatus.late && server.lateMinutes > 0)
        l10n.hrPresenceCalendarLate(server.lateMinutes),
      if (reason != null)
        StaffAttendanceLabels.reason(l10n, reason)
      else if (server.status.isIncident)
        l10n.hrPresenceCalendarUnjustified,
      if (note != null && note.isNotEmpty) note,
    ];
    final onOpenRegister = this.onOpenRegister;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloPanelCard(
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PresenceStatusPill(status: server.status),
              if (facts.isNotEmpty)
                Text(
                  facts.join(' · '),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (onOpenRegister != null) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: EteeloButton.secondary(
              label: l10n.hrPresenceDayOpenRegister,
              icon: Icons.how_to_reg_outlined,
              onPressed: onOpenRegister,
              fullWidth: false,
            ),
          ),
        ],
      ],
    );
  }
}

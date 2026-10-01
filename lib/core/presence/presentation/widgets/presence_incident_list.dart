import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_month_views.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_status_pill.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les retards et absences d'une personne sur le mois : le jour, le statut,
/// l'heure et les minutes, et la justification (vert) ou « Non justifié »
/// (rouge). [reasonLabel] nomme les motifs du module.
class PresenceIncidentList<R extends Object> extends StatelessWidget {
  final List<PresenceIncident<R>> incidents;
  final String Function(R reason) reasonLabel;

  const PresenceIncidentList({
    super.key,
    required this.incidents,
    required this.reasonLabel,
  });

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
        for (final incident in incidents)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    PresenceLabels.longDay(dates, incident.day),
                    style: AppTypography.bodyMedium,
                  ),
                ),
                PresenceStatusPill(status: incident.status),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: Text(
                    incident.status == PresenceStatus.late
                        ? '${incident.arrival?.wire ?? ''} · '
                              '+${l10n.presenceMarkMinutes(incident.lateMinutes)}'
                        : '',
                    style: AppTypography.bodySmall,
                  ),
                ),
                Expanded(flex: 3, child: _Reason(incident, reasonLabel)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Reason<R extends Object> extends StatelessWidget {
  final PresenceIncident<R> incident;
  final String Function(R reason) reasonLabel;

  const _Reason(this.incident, this.reasonLabel);

  @override
  Widget build(BuildContext context) {
    final reason = incident.reason;
    return Text(
      reason == null
          ? AppLocalizations.of(context)!.presenceMarkUnjustified
          : reasonLabel(reason),
      style: AppTypography.labelMedium.copyWith(
        color: reason == null
            ? AppColors.presenceMarkAbsentInk
            : AppColors.presenceMarkPresentInk,
      ),
    );
  }
}

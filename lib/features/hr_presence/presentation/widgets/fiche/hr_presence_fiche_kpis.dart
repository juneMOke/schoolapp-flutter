import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_tile.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_kpi_grid.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les taux de la fiche (spec §12) : présence, retard, absence, puis les
/// heures d'un vacataire à l'heure ou les jours non pointés.
class HrPresenceFicheKpis extends StatelessWidget {
  final HrAttendanceKpis kpis;
  final bool hourly;

  const HrPresenceFicheKpis({
    super.key,
    required this.kpis,
    required this.hourly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String rate(int? pct) =>
        pct == null ? l10n.hrPresenceNoValue : l10n.presenceRateValue(pct);
    return PresenceKpiGrid(
      tiles: [
        PresenceCountTile(
          tone: PresenceStatus.present,
          label: l10n.hrPresenceKpiRate,
          value: rate(kpis.presenceRatePct),
          detail: l10n.hrPresenceFicheRateDetail(kpis.presences, kpis.scored),
        ),
        PresenceCountTile(
          tone: PresenceStatus.late,
          label: l10n.hrPresenceFicheLateRate,
          value: rate(kpis.lateRatePct),
          detail: l10n.hrPresenceFicheLateDetail(kpis.late, kpis.lateMinutes),
        ),
        PresenceCountTile(
          tone: PresenceStatus.absent,
          label: l10n.hrPresenceFicheAbsenceRate,
          value: rate(kpis.absenceRatePct),
          detail: l10n.presenceMarkKpiAbsencesDetail(
            kpis.justifiedAbsences,
            kpis.unjustifiedAbsences,
          ),
        ),
        if (hourly)
          PresenceCountTile(
            tone: PresenceStatus.none,
            label: l10n.staffAttendanceKpiHours,
            value: PresenceLabels.hours(l10n, kpis.workedMinutes),
          )
        else
          PresenceCountTile(
            tone: PresenceStatus.none,
            label: l10n.presenceMarkKpiNotMarked,
            value: '${kpis.unscored}',
          ),
      ],
    );
  }
}

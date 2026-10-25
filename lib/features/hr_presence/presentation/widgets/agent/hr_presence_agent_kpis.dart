import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_tile.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_kpi_grid.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre tuiles du mois d'un agent : présences sur jours pointés,
/// retards, absences, puis ses heures (vacataire à l'heure) ou ses jours non
/// pointés. Plus de « jours prestés » : une absence n'est jamais retenue
/// (E3, F7).
class HrPresenceAgentKpis extends StatelessWidget {
  final HrAttendanceAgentMonth month;

  const HrPresenceAgentKpis({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kpis = month.kpis;
    final lateUnjustified = month.days
        .where((d) => d.status == PresenceStatus.late && !d.isJustified)
        .length;
    return PresenceKpiGrid(
      tiles: [
        PresenceCountTile(
          tone: PresenceStatus.present,
          label: l10n.presenceMarkKpiPresences,
          value: l10n.presenceMarkKpiRatio(kpis.presences, kpis.scored),
          detail: l10n.hrPresenceAgentClassDays(month.classDays, kpis.unscored),
        ),
        PresenceCountTile.lates(
          l10n,
          count: kpis.late,
          minutes: kpis.lateMinutes,
          unjustified: lateUnjustified,
        ),
        PresenceCountTile.absences(
          l10n,
          count: kpis.absences,
          justified: kpis.justifiedAbsences,
          unjustified: kpis.unjustifiedAbsences,
        ),
        if (month.agent.isHourly)
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

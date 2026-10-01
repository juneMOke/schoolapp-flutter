import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_rate_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_tile.dart';
import 'package:school_app_flutter/features/attendances/domain/services/student_month_stats.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_kpi_grid.dart';

/// Les quatre indicateurs de la fiche mensuelle : présences et taux,
/// retards, absences, non pointés.
class StudentMonthKpis extends StatelessWidget {
  final StudentMonthStats stats;

  const StudentMonthKpis({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = [
      PresenceCountTile(
        tone: PresenceStatus.present,
        label: l10n.presenceMarkKpiPresences,
        value: l10n.presenceMarkKpiRatio(stats.presences, stats.schoolDays),
        detail: l10n.classPresenceKpiRate(PresenceRateTone.percent(stats.rate)),
      ),
      PresenceCountTile(
        tone: PresenceStatus.late,
        label: l10n.presenceMarkKpiLates,
        value: '${stats.late}',
        detail: l10n.presenceMarkKpiLatesDetail(
          stats.lateMinutes,
          stats.lateUnjustified,
        ),
      ),
      PresenceCountTile(
        tone: PresenceStatus.absent,
        label: l10n.presenceMarkKpiAbsences,
        value: '${stats.absent}',
        detail: l10n.presenceMarkKpiAbsencesDetail(
          stats.absentJustified,
          stats.absentUnjustified,
        ),
      ),
      PresenceCountTile(
        tone: PresenceStatus.none,
        label: l10n.presenceMarkKpiNotMarked,
        value: '${stats.notMarked}',
        detail: stats.notMarked == 0
            ? l10n.classPresenceRegisterComplete
            : null,
      ),
    ];
    return PresenceKpiGrid(tiles: tiles);
  }
}

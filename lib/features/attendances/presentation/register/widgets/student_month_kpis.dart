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
      PresenceCountTile.lates(
        l10n,
        count: stats.late,
        minutes: stats.lateMinutes,
        unjustified: stats.lateUnjustified,
      ),
      PresenceCountTile.absences(
        l10n,
        count: stats.absent,
        justified: stats.absentJustified,
        unjustified: stats.absentUnjustified,
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

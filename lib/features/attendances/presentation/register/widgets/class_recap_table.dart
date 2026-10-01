import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_rate_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau du récapitulatif : une ligne par élève ; toucher une ligne
/// ouvre sa fiche mensuelle.
class ClassRecapTable extends StatelessWidget {
  final List<ClassRecapRow> rows;
  final RecordSyncState sync;
  final ValueChanged<ClassRecapRow> onOpen;

  const ClassRecapTable({
    super.key,
    required this.rows,
    required this.sync,
    required this.onOpen,
  });

  static const List<double?> _widths = [
    null,
    AppDimensions.classRecapColPresences,
    AppDimensions.classRecapColRate,
    AppDimensions.classRecapColLates,
    AppDimensions.classRecapColAbsences,
    AppDimensions.classRecapColSync,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      minWidth: AppDimensions.classRecapMinWidth,
      widths: _widths,
      endAligned: const {2},
      headers: [
        l10n.classPresenceColStudent,
        l10n.presenceMarkKpiPresences,
        l10n.classPresenceColRate,
        l10n.presenceMarkKpiLates,
        l10n.presenceMarkKpiAbsences,
        l10n.classPresenceColSync,
      ],
      rowCount: rows.length,
      row: (context, index) =>
          _RecapRow(row: rows[index], sync: sync, onOpen: onOpen),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final ClassRecapRow row;
  final RecordSyncState sync;
  final ValueChanged<ClassRecapRow> onOpen;

  const _RecapRow({
    required this.row,
    required this.sync,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = row.stats;
    final student = row.student;
    final tone = PresenceRateTone.of(stats.rate);
    final style = EteeloColumnTableRow.figures();
    return EteeloColumnTableRow(
      onTap: () => onOpen(row),
      widths: ClassRecapTable._widths,
      cells: [
        Row(
          children: [
            PersonAvatar(
              firstName: student.firstName,
              lastName: student.lastName,
              personId: student.id,
              size: AppDimensions.presenceMarkIconButtonSize,
            ),
            const SizedBox(width: AppSpacing.sm),
            if (stats.toWatch) ...[
              Container(
                width: AppDimensions.classRecapWatchDot,
                height: AppDimensions.classRecapWatchDot,
                decoration: const BoxDecoration(
                  color: AppColors.presenceMarkAbsent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Text(
                '${student.number}. ${student.fullName}',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.presenceMarkKpiRatio(stats.presences, stats.schoolDays),
              style: style,
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: AppDimensions.classRecapRateBarWidth,
              child: ClipRRect(
                borderRadius: AppRadius.brPill,
                child: LinearProgressIndicator(
                  value: stats.rate,
                  color: tone.color,
                  backgroundColor: AppColors.border,
                ),
              ),
            ),
          ],
        ),
        Text(
          l10n.classPresenceKpiRate(PresenceRateTone.percent(stats.rate)),
          textAlign: TextAlign.end,
          style: EteeloColumnTableRow.figures(color: tone.ink, strong: true),
        ),
        Text(
          l10n.classPresenceLatesValue(stats.late, stats.lateMinutes),
          style: style,
        ),
        Text(
          l10n.presenceMarkKpiAbsencesDetail(
            stats.absentJustified,
            stats.absentUnjustified,
          ),
          style: style,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: RecordSyncPill(state: sync),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau du récapitulatif : une ligne par agent ; toucher une ligne
/// ouvre sa fiche mensuelle. Défile horizontalement sous sa largeur plancher.
class StaffRecapTable extends StatelessWidget {
  final List<StaffRecapRow> rows;
  final ValueChanged<StaffRecapRow> onOpen;

  const StaffRecapTable({super.key, required this.rows, required this.onOpen});

  static const List<double?> _widths = [
    null,
    AppDimensions.staffAttendanceRecapColContract,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.staffAttendanceRecapColSync,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      minWidth: AppDimensions.staffAttendanceRecapMinWidth,
      widths: _widths,
      headers: [
        l10n.staffAttendanceColAgent,
        l10n.staffAttendanceRecapColContract,
        l10n.presenceMarkKpiPresences,
        l10n.presenceMarkKpiLates,
        l10n.presenceMarkKpiAbsences,
        l10n.staffAttendanceRecapColHours,
        l10n.staffAttendanceRecapColSync,
      ],
      rowCount: rows.length,
      row: (context, index) => _RecapRow(row: rows[index], onOpen: onOpen),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final StaffRecapRow row;
  final ValueChanged<StaffRecapRow> onOpen;

  const _RecapRow({required this.row, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = row.stats;
    final style = EteeloColumnTableRow.figures();
    return EteeloColumnTableRow(
      onTap: () => onOpen(row),
      widths: StaffRecapTable._widths,
      cells: [
        Row(
          children: [
            StaffAvatar(
              member: row.member,
              sync: row.sync,
              size: AppDimensions.presenceMarkIconButtonSize,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                row.member.fullName,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: StaffContractBadge(kind: row.kind),
        ),
        Text(
          stats.isHourly
              ? '${stats.present}'
              : l10n.presenceMarkKpiRatio(stats.present, stats.workDays),
          style: style,
        ),
        Text('${stats.late}', style: style),
        Text(
          l10n.presenceMarkKpiAbsencesDetail(
            stats.absentJustified,
            stats.absentUnjustified,
          ),
          style: style,
        ),
        Text(
          stats.isHourly
              ? PresenceLabels.hours(l10n, stats.workedMinutes)
              : '—',
          style: style,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: RecordSyncPill(state: row.sync),
        ),
      ],
    );
  }
}

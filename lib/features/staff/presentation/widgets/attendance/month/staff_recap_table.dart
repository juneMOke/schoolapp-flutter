import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_sync_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau du récapitulatif : une ligne par agent ; toucher une ligne
/// ouvre sa fiche mensuelle. Défile horizontalement sous sa largeur plancher.
class StaffRecapTable extends StatelessWidget {
  final List<StaffRecapRow> rows;
  final ValueChanged<StaffRecapRow> onOpen;

  const StaffRecapTable({super.key, required this.rows, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget head(String text) => Text(
      text.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: AppTypography.labelSmall.copyWith(color: AppColors.textMutedAa),
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width:
              constraints.maxWidth < AppDimensions.staffAttendanceRecapMinWidth
              ? AppDimensions.staffAttendanceRecapMinWidth
              : constraints.maxWidth,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.brSm,
                ),
                child: _RecapLayout(
                  cells: [
                    head(l10n.staffAttendanceColAgent),
                    head(l10n.staffAttendanceRecapColContract),
                    head(l10n.staffAttendanceKpiPresences),
                    head(l10n.staffAttendanceKpiLates),
                    head(l10n.staffAttendanceKpiAbsences),
                    head(l10n.staffAttendanceRecapColHours),
                    head(l10n.staffAttendanceRecapColSync),
                  ],
                ),
              ),
              for (final row in rows) _RecapRow(row: row, onOpen: onOpen),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les colonnes, partagées par l'en-tête et les lignes.
class _RecapLayout extends StatelessWidget {
  final List<Widget> cells;

  const _RecapLayout({required this.cells});

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
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, cell) in cells.indexed)
        if (_widths[index] == null)
          Expanded(child: cell)
        else
          SizedBox(width: _widths[index], child: cell),
    ],
  );
}

class _RecapRow extends StatelessWidget {
  final StaffRecapRow row;
  final ValueChanged<StaffRecapRow> onOpen;

  const _RecapRow({required this.row, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = row.stats;
    final style = AppTypography.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return InkWell(
      onTap: () => onOpen(row),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: _RecapLayout(
          cells: [
            Row(
              children: [
                StaffAvatar(
                  member: row.member,
                  sync: row.sync,
                  size: AppDimensions.staffAttendanceIconButtonSize,
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
                  : l10n.staffAttendanceKpiRatio(stats.present, stats.workDays),
              style: style,
            ),
            Text('${stats.late}', style: style),
            Text(
              l10n.staffAttendanceKpiAbsencesDetail(
                stats.absentJustified,
                stats.absentUnjustified,
              ),
              style: style,
            ),
            Text(
              stats.isHourly
                  ? StaffAttendanceLabels.hours(l10n, stats.workedMinutes)
                  : '—',
              style: style,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: StaffSyncPill(state: row.sync),
            ),
          ],
        ),
      ),
    );
  }
}

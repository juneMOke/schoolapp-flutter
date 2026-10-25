import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau du récapitulatif : une ligne par agent, ses totaux du mois ;
/// toucher une ligne ouvre sa fiche individuelle sur ce mois. Défile
/// horizontalement sous sa largeur plancher.
class HrPresenceRecapTable extends StatelessWidget {
  final List<HrAttendanceRecapRow> rows;
  final ValueChanged<HrAttendanceRecapRow> onOpen;

  const HrPresenceRecapTable({
    super.key,
    required this.rows,
    required this.onOpen,
  });

  static const List<double?> _widths = [
    null,
    AppDimensions.staffAttendanceRecapColContract,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.hrPresenceRecapColHours,
    EteeloDataTableTheme.trailingSlotWidth,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      minWidth: AppDimensions.staffAttendanceRecapMinWidth,
      widths: _widths,
      endAligned: const {6},
      headers: [
        l10n.staffAttendanceColAgent,
        l10n.staffAttendanceRecapColContract,
        l10n.presenceMarkKpiPresences,
        l10n.presenceMarkKpiLates,
        l10n.presenceMarkKpiAbsences,
        l10n.presenceMarkKpiNotMarked,
        l10n.staffAttendanceRecapColHours,
        '',
      ],
      rowCount: rows.length,
      row: (context, index) => _Row(row: rows[index], onOpen: onOpen),
    );
  }
}

class _Row extends StatelessWidget {
  final HrAttendanceRecapRow row;
  final ValueChanged<HrAttendanceRecapRow> onOpen;

  const _Row({required this.row, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = EteeloColumnTableRow.figures();
    final agent = row.agent;
    final amount = row.amount;
    return EteeloColumnTableRow(
      onTap: () => onOpen(row),
      widths: HrPresenceRecapTable._widths,
      cells: [
        Row(
          children: [
            PersonAvatar(
              firstName: agent.firstName ?? '',
              lastName: agent.lastName,
              personId: agent.staffMemberId,
              size: AvatarSize.md,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HrPresenceLabels.fullName(agent),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge,
                  ),
                  if (agent.jobTitle != null)
                    Text(
                      agent.jobTitle!,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: StaffContractBadge(kind: agent.contractKind),
        ),
        Text(
          agent.isHourly
              ? l10n.hrPresenceRecapDaysWorked(row.presences)
              : l10n.presenceMarkKpiRatio(row.presences, row.classDays),
          style: style,
        ),
        Text(
          row.late == 0
              ? l10n.hrPresenceNoValue
              : l10n.hrPresenceLateCell(row.late, row.lateMinutes),
          style: style,
        ),
        Text(
          l10n.presenceMarkKpiAbsencesDetail(
            row.justifiedAbsences,
            row.unjustifiedAbsences,
          ),
          style: row.unjustifiedAbsences > 0
              ? style.copyWith(color: AppColors.presenceMarkAbsentInk)
              : style,
        ),
        Text(
          row.unscored == 0 ? l10n.hrPresenceNoValue : '${row.unscored}',
          style: style,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            agent.isHourly
                ? [
                    PresenceLabels.hours(l10n, row.workedMinutes),
                    if (amount != null) MoneyFormat.format(amount),
                  ].join(' · ')
                : l10n.hrPresenceNoValue,
            style: style,
            textAlign: TextAlign.end,
          ),
        ),
        // L'œil des tables de l'app : toute la ligne ouvre aussi.
        DataTableTrailingRegistry.build(
          context,
          DataTableTrailingSpec(
            type: DataTableTrailingType.eye,
            tooltip: l10n.hrPresenceStaffOpen,
            onTap: () => onOpen(row),
          ),
        ),
      ],
    );
  }
}

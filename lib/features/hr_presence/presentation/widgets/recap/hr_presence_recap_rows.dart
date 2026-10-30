import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_share_bar.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_absences.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_pay_cells.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_table.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les lignes du récapitulatif, rendues telles quelles : le tableau en fait
/// des cartes sur un téléphone, à condition de recevoir la ligne elle-même.
abstract final class HrPresenceRecapRows {
  /// La ligne d'un agent : qui il est (et ce que la tablette n'a pas encore
  /// envoyé pour lui — sa ligne servie ne le compte pas encore), son contrat,
  /// ses présences sur les jours de classe, ses absences et retards, ses
  /// jours non pointés, puis ses montants du mois ou ses heures de vacation.
  static EteeloColumnTableRow agent(
    BuildContext context, {
    required HrAttendanceRecapRow row,
    required HrPresenceRecapColumns columns,
    required int unsynced,
    required ValueChanged<HrAttendanceRecapRow> onOpen,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final style = EteeloColumnTableRow.figures();
    final agent = row.agent;
    final amount = row.amount;
    return EteeloColumnTableRow(
      onTap: () => onOpen(row),
      widths: columns.widths,
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
                  // Sur deux lignes plutôt que tronqué : le nom est ce qu'on
                  // cherche.
                  Text(
                    HrPresenceLabels.fullName(agent),
                    maxLines: 2,
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
                  if (unsynced > 0)
                    const RecordSyncPill(state: RecordSyncState.pending),
                ],
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: StaffContractBadge(kind: agent.contractKind),
        ),
        _PresenceCell(row: row),
        HrPresenceRecapAbsences(
          justified: row.justifiedAbsences,
          unjustified: row.unjustifiedAbsences,
          late: row.late,
          lateMinutes: row.lateMinutes,
        ),
        Text(
          row.unscored == 0 ? l10n.hrPresenceNoValue : '${row.unscored}',
          textAlign: TextAlign.end,
          style: row.unscored == 0
              ? style
              : style.copyWith(color: AppColors.presenceMarkLateInk),
        ),
        if (columns.pay) ...[
          HrPresenceRecapPayCells.gross(context, row),
          if (columns.deduction)
            HrPresenceRecapPayCells.deduction(context, row),
          HrPresenceRecapPayCells.grossAfter(context, row),
        ] else
          Text(
            agent.isHourly
                ? [
                    PresenceLabels.hours(l10n, row.workedMinutes),
                    if (amount != null) MoneyFormat.format(amount),
                  ].join(' · ')
                : l10n.hrPresenceNoValue,
            style: style,
            textAlign: TextAlign.end,
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

  /// Le pied : le mois entier, tel que le serveur le compte, sur le bandeau
  /// de l'en-tête comme les totaux de la Paie. Avec les montants, une ligne
  /// par devise : la première porte les comptes, les suivantes leur seul
  /// argent — deux devises ne s'additionnent jamais.
  static Widget total(
    BuildContext context, {
    required HrAttendanceRecap recap,
    required HrPresenceRecapColumns columns,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final ink = ListingTones.table.headerInk;
    final style = EteeloColumnTableRow.figures(color: ink, strong: true);
    final totals = recap.totals;
    final rate = totals.presenceRatePct;
    int sum(int Function(HrAttendanceRecapRow row) of) =>
        recap.staff.fold(0, (total, row) => total + of(row));
    final amounts = columns.pay
        ? recap.totals.amounts ?? const <HrAttendanceRecapAmount>[]
        : const <HrAttendanceRecapAmount>[];
    EteeloColumnTableRow money(HrAttendanceRecapAmount amount) =>
        EteeloColumnTableRow(
          widths: columns.widths,
          background: ListingTones.table.header,
          labelInk: ink,
          cells: [
            Text(
              l10n.hrPresenceRecapTotalCurrency(amount.currency),
              style: AppTypography.labelLarge.copyWith(color: ink),
            ),
            for (var i = 1; i < HrPresenceRecapColumns.leading; i++)
              const SizedBox.shrink(),
            ...HrPresenceRecapPayCells.totals(
              amount,
              deduction: columns.deduction,
              ink: ink,
            ),
            const SizedBox.shrink(),
          ],
        );
    final counts = EteeloColumnTableRow(
      widths: columns.widths,
      background: ListingTones.table.header,
      labelInk: ink,
      cells: [
        Text(
          l10n.hrPresenceRecapTotal(recap.staff.length),
          style: AppTypography.labelLarge.copyWith(color: ink),
        ),
        const SizedBox.shrink(),
        Text(
          rate == null ? l10n.hrPresenceNoValue : l10n.presenceRateValue(rate),
          style: style,
        ),
        HrPresenceRecapAbsences(
          justified: sum((row) => row.justifiedAbsences),
          unjustified: totals.unjustifiedAbsences,
          late: sum((row) => row.late),
          lateMinutes: sum((row) => row.lateMinutes),
          ink: ink,
        ),
        Text(
          recap.unscored == 0 ? l10n.hrPresenceNoValue : '${recap.unscored}',
          textAlign: TextAlign.end,
          style: style,
        ),
        if (columns.pay) ...[
          // Une seule devise : ses montants tiennent sur la ligne des comptes.
          if (amounts.length == 1)
            ...HrPresenceRecapPayCells.totals(
              amounts.single,
              deduction: columns.deduction,
              ink: ink,
            )
          else ...[
            for (var i = 0; i < (columns.deduction ? 3 : 2); i++)
              const SizedBox.shrink(),
          ],
        ] else
          Text(
            [
              PresenceLabels.hours(l10n, totals.workedMinutes),
              ...?totals.hourAmounts?.map(MoneyFormat.format),
            ].join(' · '),
            textAlign: TextAlign.end,
            style: style,
          ),
        const SizedBox.shrink(),
      ],
    );
    if (amounts.length < 2) return counts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [counts, for (final amount in amounts) money(amount)],
    );
  }
}

/// « 16 / 20 » sur sa barre : à l'heure, en retard, absent, en part des
/// jours de classe — le reste, en gris, ce qui n'est pas pointé. Un
/// vacataire à l'heure n'a pas de jours attendus : ses jours prestés seuls.
class _PresenceCell extends StatelessWidget {
  final HrAttendanceRecapRow row;

  const _PresenceCell({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = EteeloColumnTableRow.figures();
    if (row.agent.isHourly) {
      return Text(l10n.hrPresenceRecapDaysWorked(row.presences), style: style);
    }
    final days = row.classDays;
    int pct(int count) => days == 0 ? 0 : (count * 100 / days).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.presenceMarkKpiRatio(row.presences, days), style: style),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: AppDimensions.presenceShareBarWidth,
          child: PresenceShareBar(
            onTimePct: pct(row.presences - row.late),
            latePct: pct(row.late),
            absentPct: pct(row.justifiedAbsences + row.unjustifiedAbsences),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_rows.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les colonnes du récapitulatif. Pour qui lit la paie (`hr.pay.read`), les
/// montants du mois — brut prévu, retenue (si l'école la pratique), brut
/// après absences — remplacent les heures de vacation, que le brut prévu
/// d'un vacataire détaille.
class HrPresenceRecapColumns {
  final bool pay;
  final bool deduction;

  const HrPresenceRecapColumns({this.pay = false, this.deduction = false});

  factory HrPresenceRecapColumns.of(HrAttendanceRecap recap) {
    final pay = recap.totals.amounts != null;
    return HrPresenceRecapColumns(
      pay: pay,
      deduction: pay && recap.absenceDeductionEnabled,
    );
  }

  /// Agent, contrat, présences, absences et retards, non pointés.
  static const int leading = 5;

  List<double?> get widths => [
    null,
    AppDimensions.staffAttendanceRecapColContract,
    AppDimensions.hrPresenceRecapColPresence,
    AppDimensions.hrPresenceRecapColAbsences,
    AppDimensions.staffAttendanceRecapColCount,
    if (pay) ...[
      AppDimensions.hrPresenceRecapColMoney,
      if (deduction) AppDimensions.hrPresenceRecapColMoney,
      AppDimensions.hrPresenceRecapColMoney,
    ] else
      AppDimensions.hrPresenceRecapColHours,
    EteeloDataTableTheme.trailingSlotWidth,
  ];

  Set<int> get endAligned => {
    for (var i = leading - 1; i < widths.length - 1; i++) i,
  };

  double get minWidth => pay
      ? AppDimensions.hrPresenceRecapPayMinWidth
      : AppDimensions.hrPresenceRecapMinWidth;

  List<String> headers(AppLocalizations l10n) => [
    l10n.staffAttendanceColAgent,
    l10n.staffAttendanceRecapColContract,
    l10n.presenceMarkKpiPresences,
    l10n.hrPresenceRecapColAbsences,
    l10n.presenceMarkKpiNotMarked,
    if (pay) ...[
      l10n.hrPresenceRecapColGross,
      if (deduction) l10n.hrPresenceRecapColDeduction,
      l10n.hrPresenceRecapColGrossAfter,
    ] else
      l10n.staffAttendanceRecapColHours,
    '',
  ];
}

/// Le tableau du récapitulatif : une ligne par agent, ses totaux du mois ;
/// toucher une ligne ouvre sa fiche individuelle sur ce mois. Sur une
/// tablette en portrait il défile de côté, l'agent restant à l'écran ; sur
/// un téléphone, une carte par agent.
class HrPresenceRecapTable extends StatelessWidget {
  final List<HrAttendanceRecapRow> rows;
  final ValueChanged<HrAttendanceRecapRow> onOpen;
  final HrPresenceRecapColumns columns;

  /// Pointages encore sur la tablette, par agent.
  final Map<String, int> unsyncedByAgent;

  /// Le mois entier, pour la ligne de total ; `null` quand un filtre
  /// n'en montre qu'une partie — les totaux du serveur ne lui
  /// correspondraient plus.
  final HrAttendanceRecap? total;

  const HrPresenceRecapTable({
    super.key,
    required this.rows,
    required this.onOpen,
    this.columns = const HrPresenceRecapColumns(),
    this.unsyncedByAgent = const {},
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = this.total;
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
      minWidth: columns.minWidth,
      frozenFirstColumn: true,
      raised: true,
      widths: columns.widths,
      endAligned: columns.endAligned,
      headers: columns.headers(l10n),
      rowCount: rows.length,
      row: (context, index) {
        final row = rows[index];
        return HrPresenceRecapRows.agent(
          context,
          row: row,
          columns: columns,
          unsynced: unsyncedByAgent[row.agent.staffMemberId] ?? 0,
          onOpen: onOpen,
        );
      },
      footer: total == null
          ? null
          : HrPresenceRecapRows.total(context, recap: total, columns: columns),
    );
  }
}

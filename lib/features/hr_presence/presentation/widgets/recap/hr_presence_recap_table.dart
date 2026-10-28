import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_rows.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau du récapitulatif : une ligne par agent, ses totaux du mois ;
/// toucher une ligne ouvre sa fiche individuelle sur ce mois. Sur une
/// tablette en portrait il défile de côté, l'agent restant à l'écran ; sur
/// un téléphone, une carte par agent.
class HrPresenceRecapTable extends StatelessWidget {
  final List<HrAttendanceRecapRow> rows;
  final ValueChanged<HrAttendanceRecapRow> onOpen;

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
    this.unsyncedByAgent = const {},
    this.total,
  });

  static const List<double?> widths = [
    null,
    AppDimensions.staffAttendanceRecapColContract,
    AppDimensions.hrPresenceRecapColPresence,
    AppDimensions.hrPresenceRecapColAbsences,
    AppDimensions.staffAttendanceRecapColCount,
    AppDimensions.hrPresenceRecapColHours,
    EteeloDataTableTheme.trailingSlotWidth,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = this.total;
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
      minWidth: AppDimensions.hrPresenceRecapMinWidth,
      frozenFirstColumn: true,
      raised: true,
      widths: widths,
      endAligned: const {4, 5},
      headers: [
        l10n.staffAttendanceColAgent,
        l10n.staffAttendanceRecapColContract,
        l10n.presenceMarkKpiPresences,
        l10n.hrPresenceRecapColAbsences,
        l10n.presenceMarkKpiNotMarked,
        l10n.staffAttendanceRecapColHours,
        '',
      ],
      rowCount: rows.length,
      row: (context, index) {
        final row = rows[index];
        return HrPresenceRecapRows.agent(
          context,
          row: row,
          unsynced: unsyncedByAgent[row.agent.staffMemberId] ?? 0,
          onOpen: onOpen,
        );
      },
      footer: total == null
          ? null
          : HrPresenceRecapRows.total(context, recap: total),
    );
  }
}

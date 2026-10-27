import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre en liste : la table teintée des autres écrans
/// ([EteeloColumnTable], [ListingTones.table]) — en-tête plein, zébrure,
/// cadre. Sous sa largeur plancher, elle défile de côté et la colonne de la
/// personne reste à l'écran ; sur téléphone, la vue en cartes reste le geste
/// tactile.
///
/// Les lignes sont des `PresenceRow`, dont les cellules suivent
/// [PresenceTable.widthsOf].
class PresenceTable extends StatelessWidget {
  /// L'en-tête de la colonne « personne » (« Agent », « Élève »).
  final String personColumn;

  /// L'en-tête de la colonne des heures (« Arrivée · départ ») ; par défaut
  /// « Arrivée ».
  final String? timesColumn;

  /// `null` : pas de colonne des heures prestées.
  final String? hoursColumn;
  final List<Widget> rows;

  const PresenceTable({
    super.key,
    required this.personColumn,
    required this.rows,
    this.timesColumn,
    this.hoursColumn,
  });

  /// Les largeurs partagées par l'en-tête et les lignes : personne et retard
  /// se partagent le reste. [hours] n'existe qu'au Pointage (vacataires à
  /// l'heure).
  static List<double?> widthsOf({required bool hours}) => [
    null,
    AppDimensions.presenceMarkColStatus,
    AppDimensions.presenceMarkColTimes,
    if (hours) AppDimensions.presenceMarkColHours,
    null,
    AppDimensions.presenceMarkColAction,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = hoursColumn;
    return EteeloColumnTable(
      tone: ListingTones.table,
      minWidth: hours == null
          ? AppDimensions.presenceMarkListMinWidth
          : AppDimensions.presenceMarkListWithHoursMinWidth,
      frozenFirstColumn: true,
      widths: widthsOf(hours: hours != null),
      headers: [
        personColumn,
        l10n.presenceMarkColStatus,
        timesColumn ?? l10n.presenceMarkArrival,
        ?hours,
        l10n.presenceMarkColLate,
        '',
      ],
      rowCount: rows.length,
      row: (context, index) => rows[index],
    );
  }
}

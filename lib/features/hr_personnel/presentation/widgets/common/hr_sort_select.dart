import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'ordre d'une liste d'agents — nom, nom inversé, plus anciens, plus
/// récents.
///
/// Le seul tri qui reste à l'écran **quel que soit l'affichage** : l'en-tête
/// « Agent » du tableau disparaît en cartes (sous
/// `AppBreakpoints.dataTableCardsMax`) et en grille, ce sélecteur jamais.
class HrSortSelect extends StatelessWidget {
  final HrRosterSort value;
  final ValueChanged<HrRosterSort> onChanged;

  const HrSortSelect({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: AppDimensions.hrRosterSortWidth,
      child: EteeloSelectInput<HrRosterSort>(
        label: l10n.hrSortLabel,
        value: value,
        onChanged: (sort) {
          if (sort != null) onChanged(sort);
        },
        items: [
          for (final sort in HrRosterSort.values)
            EteeloSelectItem(
              value: sort,
              label: HrPersonnelLabels.sort(l10n, sort),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre de controle : segmente de periode (Semaine / Mois / Annee, defaut
/// Annee). Reutilise le [SegmentedTabFilter] partage.
class PresencePeriodFilter extends StatelessWidget {
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onSelected;

  const PresencePeriodFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l10n.presencePeriodFilterA11yLabel,
      child: SegmentedTabFilter<StatsPeriod>(
        options: [
          SegmentedTabOption(
            label: l10n.presencePeriodWeek,
            value: StatsPeriod.week,
          ),
          SegmentedTabOption(
            label: l10n.presencePeriodMonth,
            value: StatsPeriod.month,
          ),
          SegmentedTabOption(
            label: l10n.presencePeriodYear,
            value: StatsPeriod.year,
          ),
        ],
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }
}

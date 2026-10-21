import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Aujourd'hui · 7 jours · 30 jours — la période pilote **tout** l'écran,
/// liste des élèves comprise.
class BoutiqueDashboardPeriodFilter extends StatelessWidget {
  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  const BoutiqueDashboardPeriodFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<DashboardPeriod>(
      semanticsLabel: l10n.boutiqueDashboardPeriodA11y,
      selected: selected,
      onSelected: onChanged,
      options: [
        for (final period in DashboardPeriod.values)
          SegmentedTabOption(
            label: BoutiqueDashboardLabels.periodLabel(period, l10n),
            value: period,
          ),
      ],
    );
  }
}

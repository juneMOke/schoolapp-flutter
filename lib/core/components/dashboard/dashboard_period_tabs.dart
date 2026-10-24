import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Aujourd'hui · Cette semaine · Ce mois · Année · Période précise — la période
/// pilote **tout** l'écran, liste comprise.
///
/// Les onglets du tableau de bord des inscriptions, à l'identique : mêmes
/// fenêtres, mêmes glyphes, même style plein qui s'enroule sur deux rangs
/// plutôt que de se comprimer. Les bornes de la période précise se saisissent
/// en dessous (`DashboardRangeFields`).
///
/// Partagés par les tableaux de bord qui interrogent le serveur sur un
/// `from` / `to` (Boutique, RH · Présences) : un directeur qui passe de l'un à
/// l'autre doit lire les mêmes cinq choix, dans le même ordre.
class DashboardPeriodTabs extends StatelessWidget {
  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  const DashboardPeriodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Les glyphes des inscriptions : de familles différentes — horloge,
  /// calendrier nu, calendrier réglé, historique, entonnoir — pour rester
  /// distincts à 16 dp.
  static IconData _iconOf(DashboardPeriod period) => switch (period) {
    DashboardPeriod.today => Icons.schedule_outlined,
    DashboardPeriod.week => Icons.calendar_today_outlined,
    DashboardPeriod.month => Icons.event_note_outlined,
    DashboardPeriod.year => Icons.history_outlined,
    DashboardPeriod.custom => Icons.filter_alt_outlined,
  };

  /// Le nom d'une période, tel que l'onglet l'écrit.
  static String labelOf(DashboardPeriod period, AppLocalizations l10n) =>
      switch (period) {
        DashboardPeriod.today => l10n.dashboardPeriodToday,
        DashboardPeriod.week => l10n.dashboardPeriodWeek,
        DashboardPeriod.month => l10n.dashboardPeriodMonth,
        DashboardPeriod.year => l10n.dashboardPeriodYear,
        DashboardPeriod.custom => l10n.dashboardPeriodCustom,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<DashboardPeriod>(
      semanticsLabel: l10n.dashboardPeriodA11y,
      style: SegmentedTabFilterStyle.window,
      wrap: true,
      selected: selected,
      onSelected: onChanged,
      options: [
        for (final period in DashboardPeriod.values)
          SegmentedTabOption(
            label: labelOf(period, l10n),
            value: period,
            icon: _iconOf(period),
          ),
      ],
    );
  }
}

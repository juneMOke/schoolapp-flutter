import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Journalier · Hebdomadaire · Mensuel (B1) ; Jour · Semaine · Mois sur un
/// écran étroit.
class ClosingScopeTabs extends StatelessWidget {
  final ClosingScope scope;
  final ValueChanged<ClosingScope> onChanged;

  const ClosingScopeTabs({
    super.key,
    required this.scope,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact =
        MediaQuery.sizeOf(context).width <
        AppBreakpoints.periodFilterShortLabelsMax;
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedTabFilter<ClosingScope>(
        semanticsLabel: l10n.treasuryScopeLabel,
        selected: scope,
        onSelected: onChanged,
        expand: compact,
        options: [
          SegmentedTabOption(
            label: compact ? l10n.treasuryScopeDayShort : l10n.treasuryScopeDay,
            value: ClosingScope.day,
            icon: Icons.schedule,
          ),
          SegmentedTabOption(
            label: compact
                ? l10n.treasuryScopeWeekShort
                : l10n.treasuryScopeWeek,
            value: ClosingScope.week,
            icon: Icons.calendar_today_outlined,
          ),
          SegmentedTabOption(
            label: compact
                ? l10n.treasuryScopeMonthShort
                : l10n.treasuryScopeMonth,
            value: ClosingScope.month,
            icon: Icons.date_range,
          ),
        ],
      ),
    );
  }
}

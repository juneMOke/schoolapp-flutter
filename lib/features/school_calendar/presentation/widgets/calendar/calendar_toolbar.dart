import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_filters.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre d'outils (spec §4.6 T) : la vue, le mois avec « Mois en cours »,
/// la source, et — si l'école a les deux rythmes — Semestres | Trimestres
/// (A1). Puis la légende-filtre (L), une puce à compteur par nature (I8).
/// En [compact], la source et le rythme passent derrière « Filtres » : sur
/// un téléphone, ils empilaient deux rangées de plus avant la grille.
class CalendarToolbar extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;
  final bool compact;

  const CalendarToolbar({
    super.key,
    required this.state,
    required this.cubit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final month = state.month;
    final rhythms = state.scopes.rhythms;
    final thisMonth = DateTime.utc(state.today.year, state.today.month);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedTabFilter<CalendarView>(
          semanticsLabel: l10n.schoolCalendarTitle,
          selected: state.view,
          onSelected: cubit.setView,
          options: [
            SegmentedTabOption(
              label: l10n.schoolCalendarViewYear,
              value: CalendarView.year,
            ),
            SegmentedTabOption(
              label: l10n.schoolCalendarViewMonth,
              value: CalendarView.month,
            ),
            SegmentedTabOption(
              label: l10n.schoolCalendarViewList,
              value: CalendarView.list,
            ),
          ],
        ),
        if (state.view == CalendarView.month && month != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.schoolCalendarPreviousMonth,
                onPressed: () => cubit.shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                MaterialLocalizations.of(context).formatMonthYear(month),
                style: AppTypography.titleSmall,
              ),
              IconButton(
                tooltip: l10n.schoolCalendarNextMonth,
                onPressed: () => cubit.shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
              if (month != thisMonth)
                TextButton(
                  onPressed: cubit.showCurrentMonth,
                  child: Text(l10n.schoolCalendarCurrentMonth),
                ),
            ],
          ),
        if (compact)
          CalendarFiltersButton(state: state, cubit: cubit)
        else ...[
          CalendarSourceFilterControl(state: state, cubit: cubit),
          if (rhythms.length > 1)
            CalendarRhythmFilterControl(state: state, cubit: cubit),
        ],
      ],
    );
  }
}

/// La légende-filtre : une puce par nature, pleine quand elle est montrée ;
/// touchée, elle masque la nature dans les trois vues (A14). Le compteur
/// reste affiché. La rangée défile de côté plutôt que de passer à la ligne.
class CalendarLegend extends StatefulWidget {
  final List<CalendarElement> elements;
  final Set<CalendarNature> hidden;
  final ValueChanged<CalendarNature> onToggle;

  const CalendarLegend({
    super.key,
    required this.elements,
    required this.hidden,
    required this.onToggle,
  });

  @override
  State<CalendarLegend> createState() => _CalendarLegendState();
}

class _CalendarLegendState extends State<CalendarLegend> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elements = widget.elements;
    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            for (final nature in CalendarNature.values) ...[
              EteeloFilterChip(
                label: CalendarLabels.natureShort(l10n, nature),
                count: elements.where((e) => e.nature == nature).length,
                selected: !widget.hidden.contains(nature),
                color: nature.tone.tone,
                soft: nature.tone.soft,
                ink: nature.tone.ink,
                icon: nature.tone.icon,
                onTap: () => widget.onToggle(nature),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

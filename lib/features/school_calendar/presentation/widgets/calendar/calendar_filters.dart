import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La source : Tout | National | École.
class CalendarSourceFilterControl extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;

  const CalendarSourceFilterControl({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<CalendarSourceFilter>(
      semanticsLabel: l10n.schoolCalendarSource,
      selected: state.source,
      onSelected: cubit.setSource,
      options: [
        SegmentedTabOption(
          label: l10n.schoolCalendarSourceAll,
          value: CalendarSourceFilter.all,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarSourceNational,
          value: CalendarSourceFilter.national,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarSourceSchool,
          value: CalendarSourceFilter.school,
        ),
      ],
    );
  }
}

/// Semestres | Trimestres, quand l'école a les deux rythmes (A1).
class CalendarRhythmFilterControl extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;

  const CalendarRhythmFilterControl({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<PeriodRhythm>(
      semanticsLabel: l10n.schoolCalendarPeriod,
      selected: state.effectiveRhythm ?? state.scopes.rhythms.first,
      onSelected: cubit.setRhythm,
      options: [
        SegmentedTabOption(
          label: l10n.schoolCalendarRhythmSemesters,
          value: PeriodRhythm.semester,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarRhythmTrimesters,
          value: PeriodRhythm.trimester,
        ),
      ],
    );
  }
}

/// « Filtres » d'un téléphone : la source et le rythme dans une feuille. Une
/// pastille dit qu'une source autre que « Tout » est retenue.
class CalendarFiltersButton extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;

  const CalendarFiltersButton({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => showEteeloAdaptiveSheet<void>(
        context: context,
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const _FiltersSheet()),
      ),
      icon: Badge(
        isLabelVisible: state.source != CalendarSourceFilter.all,
        smallSize: AppSpacing.sm,
        child: const Icon(Icons.tune_rounded),
      ),
      label: Text(l10n.schoolCalendarFilters),
    );
  }
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SchoolCalendarCubit>();
    return BlocBuilder<SchoolCalendarCubit, SchoolCalendarState>(
      buildWhen: (a, b) =>
          a.source != b.source ||
          a.effectiveRhythm != b.effectiveRhythm ||
          a.scopes != b.scopes,
      // Toute la largeur de la feuille : sans cela, la colonne prenait celle
      // de son plus long enfant (252 dp sur 360).
      builder: (context, state) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.schoolCalendarFilters, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.schoolCalendarSource, style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            CalendarSourceFilterControl(state: state, cubit: cubit),
            if (state.scopes.rhythms.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.schoolCalendarPeriod, style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              CalendarRhythmFilterControl(state: state, cubit: cubit),
            ],
          ],
        ),
      ),
    );
  }
}

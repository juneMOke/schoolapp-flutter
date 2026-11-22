import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_filters.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_month_nav.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les onglets de vue du calendrier (maquette `CalTabs`) : crème, l'actif en
/// terre cuite pleine.
const calendarViewTabsStyle = SegmentedTabFilterStyle(
  backgroundColor: AppColors.calendarTabsSurface,
  borderColor: AppColors.calendarTabsBorder,
  borderRadius: AppDimensions.calendarTabsRadius,
  containerPadding: EdgeInsets.all(AppDimensions.calendarTabsPadding),
  containerHeight: null,
  itemHeight: AppDimensions.calendarTabHeight,
  itemBorderRadius: AppDimensions.calendarTabRadius,
  itemGap: AppDimensions.calendarTabsPadding,
  itemPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
  itemContentGap: AppSpacing.xs + AppSpacing.xs / 2,
  selectedBackgroundColor: AppColors.terreCuite,
  selectedForegroundColor: AppColors.textOnDark,
  unselectedForegroundColor: AppColors.calendarTabsInk,
  selectedShadow: AppElevation.calendarTabSelected,
);

/// La barre d'outils (spec §4.6 T, maquette `CalDetail`) : la vue, le mois
/// encadré avec « Mois en cours », puis la source — et, si l'école a les deux
/// rythmes, Semestres | Trimestres (A1), à côté de la source. En [compact]
/// (sous 600), chacun prend sa ligne et la bascule de vue toute la largeur.
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
    final tabs = SegmentedTabFilter<CalendarView>(
      semanticsLabel: l10n.schoolCalendarTitle,
      selected: state.view,
      onSelected: cubit.setView,
      style: calendarViewTabsStyle,
      expand: compact,
      options: [
        SegmentedTabOption(
          label: l10n.schoolCalendarViewYear,
          icon: Icons.grid_view_rounded,
          value: CalendarView.year,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarViewMonth,
          icon: Icons.calendar_today_outlined,
          value: CalendarView.month,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarViewList,
          icon: Icons.format_list_bulleted_rounded,
          value: CalendarView.list,
        ),
      ],
    );
    final nav = state.view == CalendarView.month && state.month != null
        ? CalendarMonthNav(state: state, cubit: cubit, expand: compact)
        : null;
    final filters = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (state.scopes.rhythms.length > 1)
          CalendarRhythmFilterControl(state: state, cubit: cubit),
        CalendarSourceFilterControl(state: state, cubit: cubit),
      ],
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tabs,
          if (nav != null) ...[const SizedBox(height: AppSpacing.sm), nav],
          const SizedBox(height: AppSpacing.sm),
          Align(alignment: Alignment.centerLeft, child: filters),
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [tabs, ?nav],
        ),
        filters,
      ],
    );
  }
}

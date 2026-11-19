import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_rights.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_element_list.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_month_body.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_toolbar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_year_banner.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/year/school_calendar_year_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes que la vue d'un calendrier déclenche ; la page les branche sur
/// les sur-couches (O1-O7).
class CalendarActions {
  final ValueChanged<CalendarElement> openElement;
  final ValueChanged<DateTime?> addOn;
  final VoidCallback? publish;
  final VoidCallback? duplicate;
  final VoidCallback? print;
  final VoidCallback back;

  const CalendarActions({
    required this.openElement,
    required this.addOn,
    required this.back,
    this.publish,
    this.duplicate,
    this.print,
  });
}

/// Un calendrier (spec §4.1, niveau 2) : bandeau, aide et actions, barre
/// d'outils, légende, puis la vue — le mois avec sa liste (à côté dès
/// `sideBySideMin` reçus, dessous en deçà), l'année, ou la liste.
class CalendarDetailView extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;
  final SchoolCalendar calendar;
  final CalendarRights rights;
  final bool online;
  final CalendarActions actions;

  const CalendarDetailView({
    super.key,
    required this.state,
    required this.cubit,
    required this.calendar,
    required this.rights,
    required this.online,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phase = state.phaseOf(calendar);
    final all = state.allElements;
    final canWrite = rights.canWrite && !phase.isReadOnly;
    final verify = state.toVerifyCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: actions.back,
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.schoolCalendarAll),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CalendarYearBanner(
          calendar: calendar,
          phase: phase,
          elements: all,
          today: state.today,
          rhythm: state.effectiveRhythm,
          eyebrow: l10n.schoolCalendarEyebrow,
          nationalCount: all.where((e) => e.isNational).length,
          schoolCount: all.where((e) => !e.isNational).length,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!online) EteeloNotice.warning(l10n.schoolCalendarOffline),
        _ActionsRow(phase: phase, canWrite: canWrite, actions: actions),
        if (verify > 0 && !state.verifyOnly) ...[
          const SizedBox(height: AppSpacing.sm),
          EteeloNotice.warning(l10n.schoolCalendarVerifyNotice(verify)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => cubit.setVerifyOnly(true),
              child: Text(l10n.schoolCalendarReview),
            ),
          ),
        ],
        if (state.verifyOnly)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => cubit.setVerifyOnly(false),
              child: Text(l10n.schoolCalendarShowAll),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        CalendarToolbar(state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.sm),
        CalendarLegend(
          elements: all,
          hidden: state.hiddenNatures,
          onToggle: cubit.toggleNature,
        ),
        const SizedBox(height: AppSpacing.md),
        _Body(state: state, cubit: cubit, canWrite: canWrite, actions: actions),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final CalendarPhase phase;
  final bool canWrite;
  final CalendarActions actions;

  const _ActionsRow({
    required this.phase,
    required this.canWrite,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final help = phase.isReadOnly
        ? l10n.schoolCalendarHelpArchived
        : canWrite
        ? l10n.schoolCalendarHelpDesktop
        : l10n.schoolCalendarHelpRead;
    final print = actions.print;
    final duplicate = actions.duplicate;
    final publish = actions.publish;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(help, style: AppTypography.bodySmall),
        if (print != null)
          SecondaryButton(
            label: l10n.schoolCalendarPrint,
            icon: Icons.print_outlined,
            fullWidth: false,
            onPressed: print,
          ),
        if (duplicate != null)
          SecondaryButton(
            label: l10n.schoolCalendarDuplicate,
            icon: Icons.copy_all_outlined,
            fullWidth: false,
            onPressed: duplicate,
          ),
        if (canWrite)
          SecondaryButton(
            label: l10n.schoolCalendarAdd,
            icon: Icons.add_rounded,
            fullWidth: false,
            onPressed: () => actions.addOn(null),
          ),
        if (phase == CalendarPhase.draft && publish != null)
          PrimaryButton(
            label: l10n.schoolCalendarPublish,
            icon: Icons.publish_outlined,
            fullWidth: false,
            onPressed: publish,
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;
  final bool canWrite;
  final CalendarActions actions;

  const _Body({
    required this.state,
    required this.cubit,
    required this.canWrite,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = state.visibleElements;
    final records = {for (final r in state.events) r.element.id: r};
    if (visible.isEmpty && state.allElements.isNotEmpty) {
      return EteeloEmptyResult(
        label: l10n.schoolCalendarEmptyFiltered,
        description: l10n.schoolCalendarEmptyFilteredHint,
        medallionIcon: Icons.filter_alt_off_outlined,
        fullWidthCard: true,
      );
    }
    final calendar = state.calendar!;
    switch (state.view) {
      case CalendarView.year:
        return SchoolCalendarYearGrid(
          months: [
            for (
              var m = DateTime.utc(
                calendar.startDate.year,
                calendar.startDate.month,
              );
              !m.isAfter(calendar.endDate);
              m = DateTime.utc(m.year, m.month + 1)
            )
              m,
          ],
          elements: visible,
          today: state.today,
          onMonthTap: cubit.showMonth,
        );
      case CalendarView.list:
        return EteeloPanelCard(
          child: CalendarElementList(
            elements: [
              for (final e in visible)
                if (e.nature != CalendarNature.period) e,
            ],
            records: records,
            scopes: state.scopes,
            today: state.today,
            emptyLabel: l10n.schoolCalendarNothingThisMonth,
            onOpen: actions.openElement,
            groupByMonth: true,
          ),
        );
      case CalendarView.month:
        return CalendarMonthBody(
          state: state,
          cubit: cubit,
          visible: visible,
          canWrite: canWrite,
          actions: actions,
        );
    }
  }
}

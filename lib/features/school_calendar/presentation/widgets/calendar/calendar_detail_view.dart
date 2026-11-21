import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_periods.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_rights.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/banner/calendar_year_banner.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_detail_body.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_legend.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_toolbar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_verify_notice.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un calendrier (spec §4.1, niveau 2 ; maquette `CalDetail`) : bandeau, la
/// carte d'aide et d'actions avec l'avis « à vérifier », la barre d'outils,
/// la légende, puis la vue — le mois avec sa liste (à côté dès
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
    final hasActions =
        canWrite ||
        actions.print != null ||
        actions.duplicate != null ||
        actions.officialDocument != null ||
        (phase == CalendarPhase.draft && actions.publish != null) ||
        phase.isReadOnly;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppBreakpoints.calendarMonthCompactMax;
        final lowWindow =
            MediaQuery.sizeOf(context).height <
            AppBreakpoints.calendarBannerCompactMaxHeight;
        final notice = verify > 0 && !phase.isReadOnly
            ? CalendarVerifyNotice(
                count: verify,
                filtered: state.verifyOnly,
                onToggle: () => cubit.setVerifyOnly(!state.verifyOnly),
              )
            : null;
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
              nationalCount: all.where((e) => e.isNational).length,
              schoolCount: all.where((e) => !e.isNational).length,
              compact: compact || lowWindow,
              twoColumns: lowWindow && !compact,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!online) ...[EteeloNotice.warning(l10n.schoolCalendarOffline)],
            if (hasActions || notice != null) ...[
              CalendarActionsRow(
                phase: phase,
                canWrite: canWrite,
                actions: actions,
                compact: compact,
                notice: notice,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            CalendarToolbar(state: state, cubit: cubit, compact: compact),
            const SizedBox(height: AppSpacing.sm),
            CalendarLegend(
              elements: CalendarPeriods.finest(state.sourcedElements),
              hidden: state.hiddenNatures,
              onToggle: cubit.toggleNature,
              compact: compact,
            ),
            const SizedBox(height: AppSpacing.md),
            CalendarDetailBody(
              state: state,
              cubit: cubit,
              canWrite: canWrite,
              actions: actions,
              compact: compact,
            ),
          ],
        );
      },
    );
  }
}

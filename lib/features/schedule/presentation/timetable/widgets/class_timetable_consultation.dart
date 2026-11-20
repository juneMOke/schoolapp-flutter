import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/consultation_actions.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/print_action.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/class_week_builder.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_marks.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_distribution.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_summary.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/dated_week_bar.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/session_detail_sheet.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_day_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_view_mode.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La version publiée d'une classe (EDT §4.1, colonne Consultation) : la
/// synthèse et « En cours », la semaine datée et ses jours fermés (barrés,
/// R17), la grille ou la journée, la répartition — où survoler un cours le
/// repère (I5) et toucher un domaine filtre (I6). Toucher une séance ouvre
/// O1 (I4).
class ClassTimetableConsultation extends StatefulWidget {
  final ClassTimetableState state;
  final ClassTimetableCubit cubit;
  final ClassTimetableView view;

  /// « Modifier » (I7), si l'utilisateur peut construire.
  final VoidCallback? onEdit;

  /// L'avis des gestes faits sur un brouillon fini (R18), s'il y en a.
  final Widget? ended;

  /// « Imprimer » demande le réseau : la pièce vient du serveur (R16).
  final bool online;

  const ClassTimetableConsultation({
    super.key,
    required this.state,
    required this.cubit,
    required this.view,
    this.onEdit,
    this.ended,
    this.online = true,
  });

  @override
  State<ClassTimetableConsultation> createState() =>
      _ClassTimetableConsultationState();
}

class _ClassTimetableConsultationState
    extends State<ClassTimetableConsultation> {
  String? _linked;
  String? _domain;

  void _hover(String? coursId) {
    if (_linked != coursId) setState(() => _linked = coursId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    final cubit = widget.cubit;
    final view = widget.view;
    final calendar = state.calendar;
    final isThisWeek = state.week == null;
    final monday = state.week ?? cubit.thisWeek;
    final closed = TimetableMarks.closedDays(calendar, l10n);
    final wallClock = SchoolTime.wallClock(DateTime.now());
    // R11 : « aujourd'hui » et « En cours » cette semaine seulement, jamais
    // un jour sans cours (férié, vacances).
    final weekday = isThisWeek ? CurrentSession.weekdayOf(wallClock) : null;
    final today = closed.containsKey(weekday) ? null : weekday;
    final now = isThisWeek
        ? TimetableMarks.now(view, calendar, wallClock)
        : null;
    final visible = _domain == null
        ? null
        : {
            for (final c in view.programme)
              if (c.domainId == _domain) c.coursId,
          };
    final marks = ScheduleGridMarks(
      closedDays: closed,
      currentSessionId: now?.current?.id,
      linkedCoursId: _linked,
      visibleCoursIds: visible,
      onHoverCours: _hover,
    );
    final week = ClassWeekBuilder.build(view, view.published);
    final palette = ScheduleClassPalette.byCourse(
      ClassWeekBuilder.courseVisuals(view),
    );
    void open(TimetableCell cell) => unawaited(_open(context, cell, monday));
    // R16 : seule une classe publiée s'imprime ; hors ligne, le bouton reste
    // visible et inactif, avec sa raison.
    final published = view.header?.isPublished ?? false;
    final print = published && widget.online && !state.busy
        ? () => unawaited(printTimetable(context, cubit))
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode =
            state.mode ??
            (defaultScheduleViewMode(constraints.maxWidth) ==
                    ScheduleViewMode.day
                ? ClassTimetableMode.day
                : ClassTimetableMode.week);
        final narrow = constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        return PageActionShortcut(
          action: PageAction.print,
          onInvoke: print,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?widget.ended,
              ClassTimetableSummary(
                view: view,
                cells: view.published,
                now: now,
              ),
              const SizedBox(height: AppSpacing.md),
              ConsultationActions(
                mode: mode,
                onMode: cubit.setMode,
                published: published,
                online: widget.online,
                narrow: narrow,
                onPrint: print,
                onEdit: widget.onEdit,
              ),
              const SizedBox(height: AppSpacing.sm),
              DatedWeekBar(
                monday: monday,
                isThisWeek: isThisWeek,
                onPrevious: () => unawaited(cubit.shiftWeek(-1)),
                onNext: () => unawaited(cubit.shiftWeek(1)),
                onThisWeek: () => unawaited(cubit.setWeek(null)),
              ),
              if (calendar != null) PeriodBanners(week: calendar),
              const SizedBox(height: AppSpacing.md),
              if (mode == ClassTimetableMode.week)
                ScheduleWeekGrid(
                  timetable: week,
                  palette: palette,
                  today: today,
                  keepSaturday: true,
                  marks: marks,
                  onOpenCell: open,
                )
              else
                ScheduleDayView(
                  timetable: week,
                  palette: palette,
                  today: today,
                  selectedDay: state.day ?? weekday ?? Weekday.mon,
                  onDaySelected: cubit.setDay,
                  marks: marks,
                  onOpenCell: open,
                ),
              const SizedBox(height: AppSpacing.lg),
              ClassTimetableDistribution(
                view: view,
                cells: view.published,
                linkedCoursId: _linked,
                onHoverCours: _hover,
                domainFilter: _domain,
                onDomainFilter: (d) => setState(() => _domain = d),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _open(
    BuildContext context,
    TimetableCell cell,
    DateTime monday,
  ) async {
    final view = widget.view;
    final source = [
      for (final c in view.published)
        if (c.id == cell.sessionId) c,
    ].firstOrNull;
    if (source == null) return;
    final now = widget.state.week == null
        ? TimetableMarks.now(
            view,
            widget.state.calendar,
            SchoolTime.wallClock(DateTime.now()),
          )
        : null;
    await showEteeloAdaptiveSheet<void>(
      context: context,
      builder: (_) => SessionDetailSheet(
        view: view,
        cell: source,
        currentId: now?.current?.id,
        dates: {
          for (final day in Weekday.values)
            day: CalendarDays.addDays(monday, day.index),
        },
      ),
    );
  }
}

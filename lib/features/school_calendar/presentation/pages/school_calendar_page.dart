import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/offline/online_only.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_rights.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/pages/school_calendar_page_actions.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/pages/school_calendar_print.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_detail_view.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendars_list_view.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/states/school_calendar_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Agenda & Horaires ▸ Calendrier scolaire : la liste des calendriers, puis
/// un calendrier en trois vues. L'adresse retient l'année ouverte, la vue, le
/// mois, le jour touché, les natures masquées, la source, « à vérifier » et le
/// rythme (A19 de la spec).
class SchoolCalendarPage extends StatelessWidget {
  const SchoolCalendarPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.instance<SchoolCalendarCubit>()..load(pull: true),
    child: OnlineOnly(builder: (context, online) => _Screen(online: online)),
  );
}

class _Screen extends StatelessWidget {
  final bool online;

  const _Screen({required this.online});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SchoolCalendarCubit>();
    // Un envoi accusé SUPERSEDED : prévenir une fois (CAL-R16).
    return BlocConsumer<SchoolCalendarCubit, SchoolCalendarState>(
      listenWhen: (a, b) => a.events != b.events,
      listener: (context, _) => unawaited(
        SchoolCalendarPageActions(
          context,
          cubit,
          CalendarRights.of(context),
        ).warnSuperseded(),
      ),
      builder: (context, state) => CalendarLocation(
        state: state,
        cubit: cubit,
        child: _shortcuts(
          context,
          state,
          cubit,
          AppPageBackground(
            width: PageContentWidth.wide,
            child: _content(context, state, cubit),
          ),
        ),
      ),
    );
  }

  /// CAL-I20 au poste : F5 relit, Ctrl+N ajoute (un calendrier dans la
  /// liste, un événement dans un calendrier ouvert), Ctrl+P imprime.
  Widget _shortcuts(
    BuildContext context,
    SchoolCalendarState state,
    SchoolCalendarCubit cubit,
    Widget child,
  ) {
    final rights = CalendarRights.of(context);
    final actions = SchoolCalendarPageActions(context, cubit, rights);
    final calendar = state.calendar;
    final VoidCallback? create = switch (calendar) {
      null when rights.canPublish && online => () => unawaited(
        actions.create(),
      ),
      final c? when rights.canWrite && !state.phaseOf(c).isReadOnly =>
        () => unawaited(actions.edit(day: state.selectedDay)),
      _ => null,
    };
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(cubit.load(pull: true)),
      child: PageActionShortcut(
        action: PageAction.create,
        onInvoke: create,
        child: PageActionShortcut(
          action: PageAction.print,
          onInvoke: calendar != null && calendar.isPublished
              ? () => unawaited(printSchoolCalendar(context, state))
              : null,
          child: child,
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    SchoolCalendarState state,
    SchoolCalendarCubit cubit,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final rights = CalendarRights.of(context);
    final actions = SchoolCalendarPageActions(context, cubit, rights);
    switch (state.status) {
      case SchoolCalendarStatus.loading:
        return EteeloListSkeleton(
          rowCount: 3,
          pillCount: 2,
          showAvatar: false,
          semanticsLabel: l10n.schoolCalendarLoading,
        );
      case SchoolCalendarStatus.failure:
        return SchoolCalendarErrorState(
          failure: state.failure ?? const StorageFailure(),
          onRetry: () => unawaited(cubit.load(pull: true)),
        );
      case SchoolCalendarStatus.ready:
        final calendar = state.calendar;
        if (calendar == null) {
          return CalendarsListView(
            state: state,
            canCreate: rights.canPublish && online,
            onCreate: () => unawaited(actions.create()),
            onOpen: (year) => unawaited(cubit.open(year)),
          );
        }
        final phase = state.phaseOf(calendar);
        final next = calendar.nextYearLabel;
        final nextFree =
            next != null &&
            state.library.calendars.every((c) => c.yearLabel != next);
        return CalendarDetailView(
          state: state,
          cubit: cubit,
          calendar: calendar,
          rights: rights,
          online: online,
          actions: CalendarActions(
            back: cubit.closeCalendar,
            openElement: (e) => unawaited(actions.openElement(e)),
            addOn: (day) => unawaited(actions.edit(day: day)),
            duplicate: rights.canPublish && online && nextFree
                ? () => unawaited(actions.duplicate())
                : null,
            print: calendar.isPublished
                ? () => unawaited(printSchoolCalendar(context, state))
                : null,
            publish: rights.canPublish && phase == CalendarPhase.draft
                ? () => unawaited(actions.publish(online: online))
                : null,
          ),
        );
    }
  }
}

/// Tient les réglages de l'écran d'accord avec l'adresse (LocationParamsSync).
class CalendarLocation extends StatelessWidget {
  static const yearParam = 'annee';
  static const viewParam = 'vue';
  static const monthParam = 'mois';
  static const dayParam = 'jour';
  static const hiddenParam = 'masquees';
  static const sourceParam = 'source';
  static const verifyParam = 'verifier';
  static const rhythmParam = 'rythme';

  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;
  final Widget child;

  const CalendarLocation({
    super.key,
    required this.state,
    required this.cubit,
    required this.child,
  });

  Map<String, String?> get _current {
    final month = state.month;
    final day = state.selectedDay;
    return {
      yearParam: state.openYear,
      viewParam: state.view == CalendarView.month ? null : state.view.name,
      monthParam: month == null
          ? null
          : CalendarDays.format(month).substring(0, 7),
      dayParam: day == null ? null : CalendarDays.format(day),
      hiddenParam: state.hiddenNatures.isEmpty
          ? null
          : (state.hiddenNatures.map((n) => n.wire).toList()..sort()).join(','),
      sourceParam: state.source == CalendarSourceFilter.all
          ? null
          : state.source.name,
      verifyParam: state.verifyOnly ? '1' : null,
      rhythmParam: state.rhythm?.wire,
    };
  }

  @override
  Widget build(BuildContext context) => LocationParamsSync(
    current: _current,
    quietKeys: const {monthParam},
    onLocation: (values) => unawaited(
      cubit.restore(
        year: values[yearParam],
        view: CalendarView.values.firstWhere(
          (v) => v.name == values[viewParam],
          orElse: () => CalendarView.month,
        ),
        month: CalendarDays.tryParse(
          values[monthParam] == null ? null : '${values[monthParam]}-01',
        ),
        day: CalendarDays.tryParse(values[dayParam]),
        hidden: {
          // Une valeur inconnue s'ignore (elle ne masque pas « Vie de
          // l'école » par le repli de `fromWire`).
          for (final raw in (values[hiddenParam] ?? '').split(','))
            for (final n in CalendarNature.values)
              if (n.wire == raw) n,
        },
        source: CalendarSourceFilter.values.firstWhere(
          (s) => s.name == values[sourceParam],
          orElse: () => CalendarSourceFilter.all,
        ),
        verifyOnly: values[verifyParam] == '1',
        rhythm: PeriodRhythm.fromWire(values[rhythmParam]),
      ),
    ),
    child: child,
  );
}

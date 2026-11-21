import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';

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

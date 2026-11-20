import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_calendar_reader.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_state.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// La semaine datée de l'emploi du temps (EDT-R17) : la navigation ‹ › et ce
/// que le calendrier publié dit de la semaine pour la classe choisie.
mixin DatedWeekCubit on Cubit<ClassTimetableState> {
  ClassCalendarReader? get calendarReader;

  /// Aujourd'hui, à l'heure de l'école.
  DateTime Function() get schoolToday;

  /// Le lundi de la semaine en cours.
  DateTime get thisWeek => CalendarDays.mondayOf(schoolToday());

  /// Semaine précédente / suivante (I24).
  Future<void> shiftWeek(int delta) =>
      setWeek(CalendarDays.addDays(state.week ?? thisWeek, 7 * delta));

  /// `null` : « Revenir à cette semaine ».
  Future<void> setWeek(DateTime? monday) async {
    final target = monday == null ? null : CalendarDays.mondayOf(monday);
    emit(
      target == null || target == thisWeek
          ? state.copyWith(clearWeek: true)
          : state.copyWith(week: target),
    );
    await reloadCalendar();
  }

  Future<void> reloadCalendar() async {
    final reader = calendarReader;
    final selected = state.selected;
    if (reader == null || selected == null) return;
    final monday = state.week ?? thisWeek;
    try {
      final week = await reader.week(
        selected,
        monday,
        CalendarDays.addDays(monday, 6),
      );
      if (isClosed || state.classroomId != selected.classroomId) return;
      emit(state.copyWith(calendar: week));
    } catch (_) {
      // Le calendrier n'est qu'un bandeau : sans lui, la grille reste juste.
      if (isClosed) return;
      emit(state.copyWith(clearCalendar: true));
    }
  }
}

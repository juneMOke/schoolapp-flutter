import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';

/// Les réglages de lecture d'un calendrier ouvert (vue, mois, jour, filtres) :
/// rien n'y lit la base, tout tient dans l'état — et dans l'adresse.
mixin CalendarViewControls on Cubit<SchoolCalendarState> {
  void setView(CalendarView view) =>
      emit(state.copyWith(view: view, clearSelectedDay: true));

  /// Mois précédent / suivant, dans les bornes de l'année (CAL-I3).
  void shiftMonth(int delta) {
    final calendar = state.calendar;
    final month = state.month;
    if (calendar == null || month == null) return;
    final next = DateTime.utc(month.year, month.month + delta);
    final first = DateTime.utc(
      calendar.startDate.year,
      calendar.startDate.month,
    );
    final last = DateTime.utc(calendar.endDate.year, calendar.endDate.month);
    if (next.isBefore(first) || next.isAfter(last)) return;
    emit(state.copyWith(month: next, clearSelectedDay: true));
  }

  void showMonth(DateTime month) => emit(
    state.copyWith(
      month: DateTime.utc(month.year, month.month),
      view: CalendarView.month,
      clearSelectedDay: true,
    ),
  );

  /// Toucher un jour (compact) le sélectionne ; le retoucher le libère (I7).
  void selectDay(DateTime? day) => day == null || day == state.selectedDay
      ? emit(state.copyWith(clearSelectedDay: true))
      : emit(state.copyWith(selectedDay: CalendarDays.of(day)));

  void toggleNature(CalendarNature nature) {
    final hidden = {...state.hiddenNatures};
    if (!hidden.remove(nature)) hidden.add(nature);
    emit(state.copyWith(hiddenNatures: hidden));
  }

  void setSource(CalendarSourceFilter source) =>
      emit(state.copyWith(source: source));

  void setVerifyOnly(bool value) => emit(
    state.copyWith(
      verifyOnly: value,
      view: value ? CalendarView.list : state.view,
    ),
  );

  void setRhythm(PeriodRhythm rhythm) => emit(state.copyWith(rhythm: rhythm));
}

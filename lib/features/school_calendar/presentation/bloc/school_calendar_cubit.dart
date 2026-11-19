import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';

/// Le calendrier scolaire à l'écran : la liste des calendriers, puis un
/// calendrier en trois vues. Tout se lit en local ; les gestes sur les
/// événements partent par le lot, les trois gestes en ligne passent par le
/// dépôt (A18).
class SchoolCalendarCubit extends Cubit<SchoolCalendarState> {
  final SchoolCalendarRepository _repository;
  final DateTime Function() _schoolToday;

  SchoolCalendarCubit(
    this._repository, {
    required DateTime Function() schoolToday,
  }) : _schoolToday = schoolToday,
       super(SchoolCalendarState(today: CalendarDays.of(schoolToday())));

  /// Lit la base locale ; [pull] tire d'abord les trois flux.
  Future<void> load({bool pull = false}) async {
    try {
      if (pull) await _repository.refresh();
      final library = await _repository.library();
      final scopes = await _repository.scopeOptions();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SchoolCalendarStatus.ready,
          library: library,
          scopes: scopes,
          today: CalendarDays.of(_schoolToday()),
        ),
      );
      // Une adresse rouverte avant le chargement n'avait pas encore son mois.
      final year = state.openYear;
      if (year != null && state.month == null) {
        final month = _defaultMonthOf(year);
        if (month != null) emit(state.copyWith(month: month));
      }
      await _reloadEvents();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SchoolCalendarStatus.failure,
          failure: StorageFailure(e.toString()),
        ),
      );
    }
  }

  /// Ouvre un calendrier (CAL-I1) : au mois en cours s'il est dans l'année,
  /// sinon au premier mois.
  Future<void> open(String yearLabel) async {
    final calendar = _calendarOf(yearLabel);
    emit(
      state.copyWith(
        openYear: yearLabel,
        month: calendar == null ? null : _defaultMonth(calendar),
        clearSelectedDay: true,
      ),
    );
    await _reloadEvents();
  }

  void closeCalendar() =>
      emit(state.copyWith(closeCalendar: true, events: const []));

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

  void showCurrentMonth() {
    final calendar = state.calendar;
    if (calendar != null) showMonth(_defaultMonth(calendar));
  }

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

  /// L'adresse rouverte (F5, lien) : remet chaque réglage d'un coup.
  Future<void> restore({
    required String? year,
    required CalendarView view,
    required DateTime? month,
    required DateTime? day,
    required Set<CalendarNature> hidden,
    required CalendarSourceFilter source,
    required bool verifyOnly,
    required PeriodRhythm? rhythm,
  }) async {
    final changedYear = year != state.openYear;
    emit(
      SchoolCalendarState(
        today: state.today,
        status: state.status,
        library: state.library,
        scopes: state.scopes,
        openYear: year,
        events: changedYear ? const [] : state.events,
        pendingCount: state.pendingCount,
        view: view,
        month: month ?? (year == null ? null : _defaultMonthOf(year)),
        selectedDay: day,
        hiddenNatures: hidden,
        source: source,
        verifyOnly: verifyOnly,
        rhythm: rhythm,
      ),
    );
    if (changedYear) await _reloadEvents();
  }

  // ── Gestes sur les événements (lot de synchro) ──

  String newEventId() => _repository.newEventId();

  Future<Either<Failure, Unit>> saveEvent(CalendarElement element) =>
      _write((id) => _repository.saveEvent(calendarId: id, element: element));

  /// « Date vérifiée » (CAL-I13) : une modification qui retire la marque.
  Future<Either<Failure, Unit>> verify(CalendarElement element) =>
      saveEvent(element.copyWith(toVerify: false));

  Future<Either<Failure, Unit>> deleteEvent(CalendarElement element) =>
      _write((id) => _repository.deleteEvent(calendarId: id, element: element));

  Future<Either<Failure, Unit>> _write(
    Future<Either<Failure, Unit>> Function(String calendarId) write,
  ) async {
    final calendar = state.calendar;
    if (calendar == null) return const Left(StorageFailure());
    final result = await write(calendar.id);
    await _reloadEvents();
    return result;
  }

  /// Les événements qu'un autre appareil a écrasés, rendus une fois.
  Future<List<SchoolEventRecord>> takeSuperseded() async {
    final calendar = state.calendar;
    return calendar == null
        ? const []
        : _repository.takeSuperseded(calendar.id);
  }

  // ── Gestes en ligne ──

  Future<Either<Failure, List<({String yearLabel, FrameworkState framework})>>>
  creatableYears() => _repository.creatableYears();

  Future<Either<Failure, SchoolCalendar>> create(String yearLabel) =>
      _online(_repository.create(yearLabel));

  Future<Either<Failure, SchoolCalendar>> duplicate(
    List<CalendarNature> natures,
  ) {
    final calendar = state.calendar;
    if (calendar == null) return Future.value(const Left(StorageFailure()));
    return _online(_repository.duplicate(source: calendar, natures: natures));
  }

  Future<Either<Failure, SchoolCalendar>> publish() {
    final calendar = state.calendar;
    if (calendar == null) return Future.value(const Left(StorageFailure()));
    return _online(_repository.publish(calendar));
  }

  /// Un geste en ligne réussi rouvre la bibliothèque, puis le calendrier rendu.
  Future<Either<Failure, SchoolCalendar>> _online(
    Future<Either<Failure, SchoolCalendar>> call,
  ) async {
    final result = await call;
    final calendar = result.toOption().toNullable();
    if (calendar != null && !isClosed) {
      await load();
      await open(calendar.yearLabel);
    }
    return result;
  }

  Future<void> _reloadEvents() async {
    final calendar = state.calendar;
    if (calendar == null) return;
    final events = await _repository.events(calendar.id);
    final pending = await _repository.pendingCount(calendar.id);
    if (isClosed) return;
    emit(state.copyWith(events: events, pendingCount: pending));
  }

  SchoolCalendar? _calendarOf(String yearLabel) {
    for (final c in state.library.calendars) {
      if (c.yearLabel == yearLabel) return c;
    }
    return null;
  }

  DateTime? _defaultMonthOf(String yearLabel) {
    final calendar = _calendarOf(yearLabel);
    return calendar == null ? null : _defaultMonth(calendar);
  }

  DateTime _defaultMonth(SchoolCalendar calendar) {
    final today = state.today;
    return CalendarDays.within(today, calendar.startDate, calendar.endDate)
        ? DateTime.utc(today.year, today.month)
        : DateTime.utc(calendar.startDate.year, calendar.startDate.month);
  }
}

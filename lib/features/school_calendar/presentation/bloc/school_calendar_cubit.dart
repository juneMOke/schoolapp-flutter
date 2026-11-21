import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/calendar_view_controls.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';

/// Le calendrier scolaire à l'écran : la liste des calendriers, puis un
/// calendrier en trois vues. Tout se lit en local ; les gestes sur les
/// événements partent par le lot, les trois gestes en ligne passent par le
/// dépôt (A18).
class SchoolCalendarCubit extends Cubit<SchoolCalendarState>
    with CalendarViewControls {
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
      await _reloadLibraryEvents();
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

  /// Les événements de chaque calendrier, pour les cartes de la liste (au
  /// plus une dizaine de calendriers, tous lus en local).
  Future<void> _reloadLibraryEvents() async {
    final events = <String, List<SchoolEventRecord>>{};
    final pending = <String, int>{};
    for (final c in state.library.calendars) {
      events[c.id] = await _repository.events(c.id);
      pending[c.id] = await _repository.pendingCount(c.id);
    }
    if (isClosed) return;
    emit(state.copyWith(libraryEvents: events, libraryPending: pending));
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

  void showCurrentMonth() {
    final calendar = state.calendar;
    if (calendar != null) showMonth(_defaultMonth(calendar));
  }

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
        libraryEvents: state.libraryEvents,
        libraryPending: state.libraryPending,
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

  /// Le document officiel du ministère joint au cadre de l'année ouverte.
  Future<Either<Failure, PrintableDocument>> frameworkDocument() async {
    final calendar = state.calendar;
    if (calendar == null) return const Left(StorageFailure());
    return _repository.frameworkDocument(calendar.yearLabel);
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

  /// Plusieurs suppressions dans un même lot.
  Future<Either<Failure, Unit>> deleteEvents(List<CalendarElement> elements) =>
      _write(
        (id) => _repository.deleteEvents(calendarId: id, elements: elements),
      );

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
      _online(() => _repository.create(yearLabel));

  /// Duplique le calendrier ouvert, ou [source] (une carte de la liste).
  Future<Either<Failure, SchoolCalendar>> duplicate(
    List<CalendarNature> natures, {
    SchoolCalendar? source,
  }) {
    final calendar = source ?? state.calendar;
    if (calendar == null) return Future.value(const Left(StorageFailure()));
    return _online(
      () => _repository.duplicate(source: calendar, natures: natures),
    );
  }

  Future<Either<Failure, SchoolCalendar>> publish() {
    final calendar = state.calendar;
    if (calendar == null) return Future.value(const Left(StorageFailure()));
    return _online(() => _repository.publish(calendar));
  }

  /// Un geste en ligne réussi rouvre la bibliothèque, puis le calendrier rendu.
  /// Un second appui pendant l'envoi ne relance pas le geste (I19).
  bool _inFlight = false;

  Future<Either<Failure, SchoolCalendar>> _online(
    Future<Either<Failure, SchoolCalendar>> Function() call,
  ) async {
    if (_inFlight) return const Left(StorageFailure());
    _inFlight = true;
    final Either<Failure, SchoolCalendar> result;
    try {
      result = await call();
    } finally {
      _inFlight = false;
    }
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
    try {
      final events = await _repository.events(calendar.id);
      final pending = await _repository.pendingCount(calendar.id);
      if (isClosed) return;
      emit(
        state.copyWith(
          events: events,
          pendingCount: pending,
          // La carte du calendrier suit ses gestes, sans relire la liste.
          libraryEvents: {...state.libraryEvents, calendar.id: events},
          libraryPending: {...state.libraryPending, calendar.id: pending},
        ),
      );
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

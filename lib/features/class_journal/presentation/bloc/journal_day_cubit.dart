import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_calendar.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/journal_day_loader.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_change_source.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_state.dart';

/// La page du journal : un jour, la navigation jour par jour, et — pour une
/// lecture locale — une relecture silencieuse à chaque signal
/// ([JournalChangeSource]). La lecture en ligne de la direction n'a pas de
/// signaux : [source] nul.
class JournalDayCubit extends Cubit<JournalDayState> {
  final JournalDayLoader _load;
  final JournalChangeSource? _source;
  AcademicYear? _year;
  void Function()? _unwatch;
  Timer? _midnight;
  var _seq = 0;

  /// [initialDate] : le jour à ouvrir, aujourd'hui par défaut.
  JournalDayCubit({
    required JournalDayLoader load,
    JournalChangeSource? source,
    DateTime? initialDate,
  }) : _load = load,
       _source = source,
       super(
         JournalDayIdle(date: initialDate ?? load.today(), today: load.today()),
       );

  /// Ouvre le journal, une fois l'année scolaire connue.
  Future<void> start(AcademicYear year) async {
    _year = year;
    final source = _source;
    if (source != null) {
      _unwatch ??= source.watch(() => unawaited(refresh()));
      unawaited(source.pull());
    }
    _armMidnight();
    await show(state.date);
  }

  /// Au passage de minuit à l'heure de l'école, la page se relit : « hier »
  /// n'est plus « aujourd'hui », ses séances vides deviennent non renseignées.
  void _armMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final today = SchoolTime.today(now);
    final midnight = DateTime.utc(
      today.year,
      today.month,
      today.day + 1,
    ).subtract(SchoolTime.offset);
    _midnight = Timer(midnight.difference(now.toUtc()), () {
      unawaited(refresh());
      _armMidnight();
    });
  }

  bool get canGoBack {
    final start = _year?.startDate;
    return start == null || state.date.isAfter(JournalCalendar.civilDay(start));
  }

  bool get canGoForward {
    final end = _year?.endDate;
    return end == null || state.date.isBefore(JournalCalendar.civilDay(end));
  }

  Future<void> previous() async {
    if (canGoBack) await show(_shift(state.date, -1));
  }

  Future<void> next() async {
    if (canGoForward) await show(_shift(state.date, 1));
  }

  Future<void> goToday() => show(_load.today());

  Future<void> show(DateTime date) async {
    final today = _load.today();
    emit(JournalDayLoading(date: date, today: today));
    await _read(date, today, keepOnFailure: false);
  }

  /// Relecture du jour affiché : un échec ne remplace jamais une page déjà
  /// affichée.
  Future<void> refresh() async {
    if (_year == null) return;
    await _read(state.date, _load.today(), keepOnFailure: true);
  }

  Future<void> _read(
    DateTime date,
    DateTime today, {
    required bool keepOnFailure,
  }) async {
    final year = _year;
    if (year == null) return;
    final seq = ++_seq;
    final result = await _load(date, year: year);
    if (isClosed || seq != _seq) return;
    result.fold((failure) {
      if (keepOnFailure && state is JournalDayReady) return;
      emit(JournalDayFailure(failure: failure, date: date, today: today));
    }, (day) => emit(JournalDayReady(day: day, date: date, today: today)));
  }

  static DateTime _shift(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  @override
  Future<void> close() {
    _midnight?.cancel();
    _unwatch?.call();
    return super.close();
  }
}

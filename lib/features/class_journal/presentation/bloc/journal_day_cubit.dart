import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/load_journal_day_use_case.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_change_source.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_state.dart';

/// La page du journal : un jour lu sur la tablette, la navigation jour par
/// jour, et une relecture silencieuse à chaque signal ([JournalChangeSource]).
class JournalDayCubit extends Cubit<JournalDayState> {
  final LoadJournalDayUseCase _load;
  final JournalChangeSource _source;
  AcademicYear? _year;
  void Function()? _unwatch;
  var _seq = 0;

  JournalDayCubit({
    required LoadJournalDayUseCase load,
    required JournalChangeSource source,
  }) : _load = load,
       _source = source,
       super(JournalDayIdle(date: load.today(), today: load.today()));

  /// Ouvre le journal sur aujourd'hui, une fois l'année scolaire connue.
  Future<void> start(AcademicYear year) async {
    _year = year;
    _unwatch ??= _source.watch(() => unawaited(refresh()));
    unawaited(_source.pull());
    await show(state.date);
  }

  bool get canGoBack {
    final start = _year?.startDate;
    return start == null || state.date.isAfter(_dayOf(start));
  }

  bool get canGoForward {
    final end = _year?.endDate;
    return end == null || state.date.isBefore(_dayOf(end));
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

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _shift(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}

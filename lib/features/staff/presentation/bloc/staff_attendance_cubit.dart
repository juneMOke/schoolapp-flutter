import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/presence/domain/presence_edited_days.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_navigation.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Le registre du Pointage (RH · Présences ▸ Registre) : lecture locale,
/// filtres en mémoire, gestes en file d'envoi.
///
/// La tablette lit le mois du jour affiché, et ne relit la base qu'en
/// changeant de mois, après un geste, ou quand un pull ou un flush la périme.
class StaffAttendanceCubit extends Cubit<StaffAttendanceState>
    implements PresenceDayNavigation {
  final LoadStaffAttendanceUseCase _load;
  final StaffSyncSignals _signals;
  final StaffAttendanceCommands commands;
  final DateTime Function() _now;
  void Function()? _unwatch;
  int _seq = 0;
  int _readSeq = 0;

  final _edited = PresenceEditedDays();

  /// Le jour affiché a reçu un geste depuis l'ouverture de l'écran.
  bool get shownDayEdited => _edited.contains(state.day);

  StaffAttendanceCubit({
    required LoadStaffAttendanceUseCase load,
    required StaffSyncSignals signals,
    required this.commands,
    DateTime Function() now = DateTime.now,
  }) : _load = load,
       _signals = signals,
       _now = now,
       super(_initial(now()));

  static StaffAttendanceState _initial(DateTime now) {
    final today = SchoolDayCalendar.dayOf(now);
    // Le week-end, le registre s'ouvre sur le vendredi.
    final day = SchoolDayCalendar.isWeekday(today)
        ? today
        : SchoolDayCalendar.stepWorkDay(today, -1);
    return StaffAttendanceState.initial(today: today, day: day);
  }

  Future<void> load() async {
    emit(state.copyWith(load: StaffAttendanceLoad.loading, clearFailure: true));
    _unwatch ??= _signals.watch(() => unawaited(refresh()));
    await _read(loading: true);
    if (isClosed) return;
    // Ce que la tablette sait s'affiche d'abord ; le réseau enrichit ensuite.
    unawaited(_signals.pull());
  }

  /// Relecture **silencieuse** : jamais de squelette, un échec garde l'écran.
  Future<void> refresh() => _read(loading: false);

  /// F5 : relire la tablette, puis redemander au serveur.
  Future<void> reload() async {
    await refresh();
    if (!isClosed) unawaited(_signals.pull());
  }

  Future<void> _read({required bool loading}) async {
    if (isClosed) return;
    // Deux lectures se croisent (un lien ?jour= juste après load, un signal
    // de synchro) : seule la dernière demandée écrit.
    final ticket = ++_readSeq;
    final (from, to) = _range(state.day);
    final result = await _load(from: from, to: to);
    if (isClosed || ticket != _readSeq) return;
    result.fold(
      (failure) {
        if (loading) {
          emit(
            state.copyWith(load: StaffAttendanceLoad.failure, failure: failure),
          );
        }
      },
      (snapshot) => emit(
        state.copyWith(
          load: StaffAttendanceLoad.ready,
          snapshot: snapshot,
          today: SchoolDayCalendar.dayOf(_now()),
          clearFailure: true,
        ),
      ),
    );
    // Un jour demandé avant que l'année scolaire soit connue (lien, F5) et
    // qui la précède : le registre revient au dernier jour ouvré.
    final first = state.firstDay;
    if (first != null && state.day.compareTo(first) < 0) {
      await _moveDay(state.lastWorkDay);
    }
  }

  /// Les jours lus : le mois du registre.
  static (String, String) _range(String day) {
    final month = SchoolDayCalendar.monthOf(day);
    return (
      SchoolDayCalendar.firstOf(month),
      SchoolDayCalendar.daysOf(month).last,
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────

  @override
  String get shownDay => state.day;

  @override
  String? get firstShownDay => state.firstDay;

  @override
  String get lastShownDay => state.lastWorkDay;

  /// Le jour ouvré précédent ou suivant ; jamais au-delà d'aujourd'hui.
  @override
  Future<void> stepDay(int direction) =>
      _moveDay(SchoolDayCalendar.stepWorkDay(state.day, direction));

  @override
  Future<void> goToday() => _moveDay(state.lastWorkDay);

  /// Le jour demandé par l'adresse (`?jour=`). Absent ou illisible : le
  /// dernier jour ouvré ; un samedi ou un dimanche : le vendredi d'avant.
  @override
  Future<void> showDay(String? day) {
    if (day == null || !SchoolDayCalendar.isDay(day)) return goToday();
    return _moveDay(
      SchoolDayCalendar.isWeekday(day)
          ? day
          : SchoolDayCalendar.stepWorkDay(day, -1),
    );
  }

  /// Jamais au-delà d'aujourd'hui, ni avant le début de l'année scolaire :
  /// le serveur refuserait tout pointage hors de l'année courante.
  Future<void> _moveDay(String day) async {
    final start = state.snapshot.schoolYear?.start;
    if (day.compareTo(state.today) > 0 || day == state.day) return;
    if (start != null && day.compareTo(start) < 0) return;
    final reload = _range(day) != _range(state.day);
    emit(state.copyWith(day: day));
    if (reload) await refresh();
  }

  // ── Filtres ───────────────────────────────────────────────────────────

  @override
  void showOnlyUnmarked() {
    resetDayFilters();
    setDayStatus(PresenceStatus.none);
  }

  void setDayStatus(PresenceStatus? status) =>
      emit(state.copyWith(dayQuery: state.dayQuery.withStatus(status)));

  void setDayCategory(StaffCategory? category) =>
      emit(state.copyWith(dayQuery: state.dayQuery.withCategory(category)));

  void setDayText(String text) {
    if (text != state.dayQuery.text) {
      emit(state.copyWith(dayQuery: state.dayQuery.withText(text)));
    }
  }

  void resetDayFilters() => emit(state.copyWith(dayQuery: StaffDayQuery.none));

  void setViewMode(CollectionViewMode mode) {
    if (mode != state.viewMode) emit(state.copyWith(viewMode: mode));
  }

  // ── Gestes ────────────────────────────────────────────────────────────

  /// Annonce sans rien écrire (un geste intercepté sur un jour figé).
  void announce(StaffAttendanceNotice notice) =>
      emit(state.copyWith(notice: notice.withSeq(++_seq)));

  /// Exécute un geste des [commands], relit la tablette et annonce l'issue.
  ///
  /// [touchesDay] : faux pour un geste qui n'écrit pas le jour affiché
  /// (réglages, clôture du mois).
  Future<void> perform(
    Future<StaffAttendanceNotice?> Function(StaffAttendanceCommands commands)
    gesture, {
    bool touchesDay = true,
  }) async {
    if (touchesDay) _edited.mark(state.day);
    final notice = await gesture(commands);
    if (isClosed) return;
    await refresh();
    if (isClosed || notice == null) return;
    emit(state.copyWith(notice: notice.withSeq(++_seq)));
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}

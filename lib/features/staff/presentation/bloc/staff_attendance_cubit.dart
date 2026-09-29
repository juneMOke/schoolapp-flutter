import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_view_mode.dart';

/// Le Pointage : lecture locale, filtres en mémoire, gestes en file d'envoi.
///
/// La tablette lit **deux mois** au plus — celui du registre et celui de la
/// fiche et du récapitulatif — et ne relit la base qu'en changeant de plage,
/// après un geste, ou quand un pull ou un flush la périme.
class StaffAttendanceCubit extends Cubit<StaffAttendanceState> {
  final LoadStaffAttendanceUseCase _load;
  final StaffSyncSignals _signals;
  final StaffAttendanceCommands commands;
  final DateTime Function() _now;
  void Function()? _unwatch;
  int _seq = 0;

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
    final today = StaffWorkCalendar.dayOf(now);
    // Le week-end, le registre s'ouvre sur le vendredi.
    final day = StaffWorkCalendar.isWeekday(today)
        ? today
        : StaffWorkCalendar.stepWorkDay(today, -1);
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

  Future<void> _read({required bool loading}) async {
    if (isClosed) return;
    final (from, to) = _range(state.day, state.month);
    final result = await _load(from: from, to: to);
    if (isClosed) return;
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
          today: StaffWorkCalendar.dayOf(_now()),
          clearFailure: true,
        ),
      ),
    );
  }

  /// Les jours lus : le mois du registre et le mois de la fiche.
  static (String, String) _range(String day, String month) {
    final months = [StaffWorkCalendar.monthOf(day), month]..sort();
    return (
      StaffWorkCalendar.firstOf(months.first),
      StaffWorkCalendar.daysOf(months.last).last,
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void setTab(StaffAttendanceTab tab) {
    if (tab != state.tab) emit(state.copyWith(tab: tab));
  }

  /// Le jour ouvré précédent ou suivant ; jamais au-delà d'aujourd'hui.
  Future<void> stepDay(int direction) =>
      _moveDay(StaffWorkCalendar.stepWorkDay(state.day, direction));

  Future<void> goToday() => _moveDay(state.today);

  Future<void> _moveDay(String day) async {
    if (day.compareTo(state.today) > 0 || day == state.day) return;
    final reload = _range(day, state.month) != _range(state.day, state.month);
    emit(state.copyWith(day: day));
    if (reload) await refresh();
  }

  /// Le mois précédent ou suivant ; jamais au-delà du mois en cours.
  Future<void> stepMonth(int direction) async {
    final month = StaffWorkCalendar.addMonths(state.month, direction);
    if (month.compareTo(state.today.substring(0, 7)) > 0) return;
    emit(state.copyWith(month: month));
    await refresh();
  }

  Future<void> goCurrentMonth() async {
    final month = state.today.substring(0, 7);
    if (month == state.month) return;
    emit(state.copyWith(month: month));
    await refresh();
  }

  /// Ouvre la fiche mensuelle d'un agent (depuis le sélecteur ou le récap).
  void openAgent(String staffMemberId) => emit(
    state.copyWith(
      agentId: () => staffMemberId,
      tab: StaffAttendanceTab.agentMonth,
    ),
  );

  // ── Filtres ───────────────────────────────────────────────────────────

  void setDayStatus(StaffAttendanceStatus? status) =>
      emit(state.copyWith(dayQuery: state.dayQuery.withStatus(status)));

  void setDayCategory(StaffCategory? category) =>
      emit(state.copyWith(dayQuery: state.dayQuery.withCategory(category)));

  void setDayText(String text) {
    if (text != state.dayQuery.text) {
      emit(state.copyWith(dayQuery: state.dayQuery.withText(text)));
    }
  }

  void resetDayFilters() => emit(state.copyWith(dayQuery: StaffDayQuery.none));

  void setViewMode(StaffViewMode mode) {
    if (mode != state.viewMode) emit(state.copyWith(viewMode: mode));
  }

  void toggleRecapContract(StaffContractFilter? filter) =>
      emit(state.copyWith(recapQuery: state.recapQuery.toggleContract(filter)));

  void setRecapText(String text) {
    if (text != state.recapQuery.text) {
      emit(state.copyWith(recapQuery: state.recapQuery.withText(text)));
    }
  }

  void resetRecapFilters() =>
      emit(state.copyWith(recapQuery: StaffRecapQuery.none));

  // ── Gestes ────────────────────────────────────────────────────────────

  /// Annonce sans rien écrire (un geste intercepté sur un jour figé).
  void announce(StaffAttendanceNotice notice) =>
      emit(state.copyWith(notice: notice.withSeq(++_seq)));

  /// Exécute un geste des [commands], relit la tablette et annonce l'issue.
  Future<void> perform(
    Future<StaffAttendanceNotice?> Function(StaffAttendanceCommands commands)
    gesture,
  ) async {
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

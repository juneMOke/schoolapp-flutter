import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_state.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

export 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_state.dart';

/// Le tableau de bord des présences : **une seule question au serveur** par
/// fenêtre — indicateurs, graphique, liste et PDF sur les mêmes `from` / `to`
/// (règle 14).
///
/// Changer de fenêtre montre le squelette : les chiffres d'avant ne
/// répondaient pas à la même question. Une relecture de la même fenêtre (F5,
/// fin d'un envoi) les garde jusqu'à la réponse, et un échec silencieux ne
/// les efface pas. Une réponse dépassée est jetée.
class HrPresenceDashboardCubit extends Cubit<HrPresenceDashboardState> {
  final GetHrAttendanceDashboardUseCase _getDashboard;
  final CountUnsyncedStaffAttendanceUseCase _countUnsynced;
  final StaffSyncSignals _signals;
  final DateTime Function() _now;

  DateTime? _yearStart;
  void Function()? _unwatch;
  int _ticket = 0;

  HrPresenceDashboardCubit({
    required GetHrAttendanceDashboardUseCase getDashboard,
    required CountUnsyncedStaffAttendanceUseCase countUnsynced,
    required StaffSyncSignals signals,
    DateTime Function() now = DateTime.now,
  }) : _getDashboard = getDashboard,
       _countUnsynced = countUnsynced,
       _signals = signals,
       _now = now,
       super(const HrPresenceDashboardState());

  /// [yearStart] : l'ouverture de l'année scolaire, que « Cette année » et la
  /// période précise ne dépassent pas.
  Future<void> start({DateTime? yearStart}) {
    _yearStart = yearStart;
    // Un pointage reçu par le serveur change ses chiffres : relire.
    _unwatch ??= _signals.watch(() => unawaited(reload()));
    return _load(_windowOf(state.period), period: state.period);
  }

  Future<void> setPeriod(DashboardPeriod period) {
    if (period == state.period && state.window != null) return Future.value();
    return _load(_windowOf(period), period: period);
  }

  /// Les bornes saisies de la période précise.
  Future<void> setRange(DashboardWindow window) {
    if (state.period == DashboardPeriod.custom && window == state.window) {
      return Future.value();
    }
    return _load(window, period: DashboardPeriod.custom);
  }

  /// La période et les bornes lues dans l'adresse. Des bornes absentes ou
  /// illisibles ouvrent la période précise sur sa fenêtre par défaut.
  Future<void> applyLocation({
    required DashboardPeriod period,
    DashboardWindow? range,
  }) {
    final window = period == DashboardPeriod.custom
        ? range ?? _windowOf(period)
        : _windowOf(period);
    if (period == state.period && window == state.window) {
      return Future.value();
    }
    return _load(window, period: period);
  }

  /// F5, fin d'un envoi : la même période, recalculée (minuit a pu passer),
  /// sans squelette.
  Future<void> reload() {
    final window = state.period == DashboardPeriod.custom
        ? state.window ?? _windowOf(state.period)
        : _windowOf(state.period);
    return _load(window, period: state.period);
  }

  void setText(String text) {
    if (text != state.text) emit(state.copyWith(text: text));
  }

  void clearText() => setText('');

  Future<void> _load(
    DashboardWindow window, {
    required DashboardPeriod period,
  }) async {
    final ticket = ++_ticket;
    final same = window == state.window && state.dashboard != null;
    emit(
      state.copyWith(
        period: period,
        window: window,
        status: same ? state.status : HrPresenceDashboardStatus.loading,
        dashboard: same ? state.dashboard : null,
        failure: null,
        unsynced: same ? state.unsynced : 0,
      ),
    );
    unawaited(_readUnsynced(window, ticket));
    final result = await _getDashboard(window);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) {
        if (same) return;
        emit(
          state.copyWith(
            status: HrPresenceDashboardStatus.failure,
            failure: failure,
          ),
        );
      },
      (dashboard) => emit(
        state.copyWith(
          status: HrPresenceDashboardStatus.ready,
          dashboard: dashboard,
          failure: null,
        ),
      ),
    );
  }

  /// Ce que la tablette n'a pas encore remis. Un échec de lecture locale
  /// garde le compte d'avant : il ne change pas les chiffres du serveur.
  Future<void> _readUnsynced(DashboardWindow window, int ticket) async {
    final result = await _countUnsynced(
      from: SchoolDayCalendar.dayOf(window.from),
      to: SchoolDayCalendar.dayOf(window.to),
    );
    if (isClosed || ticket != _ticket) return;
    result.fold((_) {}, (count) => emit(state.copyWith(unsynced: count)));
  }

  DashboardWindow _windowOf(DashboardPeriod period) {
    if (period != DashboardPeriod.custom) {
      return period.windowAt(_now(), yearStart: _yearStart);
    }
    // Deux semaines jusqu'à aujourd'hui (spec §1), sans remonter avant la
    // rentrée.
    final today = SchoolTime.today(_now());
    var from = DateTime(
      today.year,
      today.month,
      today.day - AppConstants.hrPresenceCustomRangeDays,
    );
    final start = _yearStart;
    if (start != null && from.isBefore(start)) {
      from = start.isAfter(today) ? today : start;
    }
    return DashboardWindow(from: from, to: today);
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}

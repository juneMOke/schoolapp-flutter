import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_state.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

export 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_state.dart';

/// Le récapitulatif pour la paie : les totaux du mois **lus au serveur**
/// (route 5, D1), et la clôture **écrite sur la tablette** puis envoyée par
/// l'outbox, comme au Pointage — elle se pose hors ligne.
///
/// La clôture n'est qu'un verrou : rien n'est transmis, la Paie relit les
/// pointages réels (E4). Un mois clos ne se rouvre pas (E6).
class HrPresenceRecapCubit extends Cubit<HrPresenceRecapState> {
  final GetHrAttendanceRecapUseCase _getRecap;
  final LoadStaffAttendanceUseCase _loadLocal;
  final CountUnsyncedStaffAttendanceUseCase _countUnsynced;
  final StaffAttendanceCommands _commands;
  final StaffSyncSignals _signals;
  void Function()? _unwatch;
  int _ticket = 0;

  HrPresenceRecapCubit({
    required GetHrAttendanceRecapUseCase getRecap,
    required LoadStaffAttendanceUseCase loadLocal,
    required CountUnsyncedStaffAttendanceUseCase countUnsynced,
    required StaffAttendanceCommands commands,
    required StaffSyncSignals signals,
    DateTime? yearStart,
    DateTime Function() now = DateTime.now,
  }) : _getRecap = getRecap,
       _loadLocal = loadLocal,
       _countUnsynced = countUnsynced,
       _commands = commands,
       _signals = signals,
       super(_initial(yearStart, now()));

  static HrPresenceRecapState _initial(DateTime? yearStart, DateTime now) {
    final current = SchoolDayCalendar.monthOf(
      // Le mois de l'école, comme le serveur : pas celui de la tablette.
      SchoolDayCalendar.dayOf(SchoolTime.today(now)),
    );
    return HrPresenceRecapState(
      month: current,
      currentMonth: current,
      firstMonth: yearStart == null
          ? null
          : SchoolDayCalendar.monthOf(SchoolDayCalendar.dayOf(yearStart)),
    );
  }

  Future<void> load() {
    // Un envoi achevé (la clôture, un pointage) change ce que sait le
    // serveur : relire, sans squelette.
    _unwatch ??= _signals.watch(() => unawaited(_read(silent: true)));
    return _read();
  }

  Future<void> retry() => _read();

  Future<void> stepMonth(int direction) {
    if (direction < 0 && !state.canStepBack) return Future.value();
    final month = SchoolDayCalendar.addMonths(state.month, direction);
    if (month.compareTo(state.currentMonth) > 0) return Future.value();
    emit(state.copyWith(month: month));
    return _read();
  }

  Future<void> goCurrentMonth() {
    if (state.isCurrentMonth) return Future.value();
    emit(state.copyWith(month: state.currentMonth));
    return _read();
  }

  /// Le mois choisi dans le sélecteur ; à venir ou d'avant la rentrée, rien.
  Future<void> showMonth(String month) {
    if (!_isValid(month) || month == state.month) return Future.value();
    emit(state.copyWith(month: month));
    return _read();
  }

  /// Le mois lu dans l'adresse ; illisible, à venir ou d'avant la rentrée,
  /// le mois en cours.
  Future<void> applyLocation(String? month) {
    final asked = month != null && _isValid(month) ? month : state.currentMonth;
    if (asked == state.month) return Future.value();
    emit(state.copyWith(month: asked));
    return _read();
  }

  bool _isValid(String month) =>
      SchoolDayCalendar.isDay('$month-01') &&
      month.compareTo(state.currentMonth) <= 0 &&
      (state.firstMonth == null || month.compareTo(state.firstMonth!) >= 0);

  void setText(String text) {
    if (text != state.text) emit(state.copyWith(text: text));
  }

  /// Un second appui sur la puce active la retire ; « Tous » (`null`) aussi.
  void toggleContract(StaffContractFilter? contract) => emit(
    state.copyWith(contract: state.contract == contract ? null : contract),
  );

  void clearFilters() => emit(state.copyWith(text: '', contract: null));

  /// Pose la clôture du mois affiché sur la tablette ; l'outbox l'envoie.
  /// Rend l'annonce à faire.
  Future<StaffAttendanceNotice?> closeMonth() async {
    if (state.closing || state.isClosed) return null;
    emit(state.copyWith(closing: true));
    final notice = await _commands.closeMonth(state.month);
    if (isClosed) return notice;
    emit(state.copyWith(closing: false));
    await _readLocal(_ticket);
    return notice;
  }

  Future<void> _read({bool silent = false}) async {
    final ticket = ++_ticket;
    if (!silent || state.recap == null) {
      emit(
        state.copyWith(
          status: HrPresenceRecapStatus.loading,
          recap: null,
          failure: null,
          localLock: null,
          unsynced: 0,
        ),
      );
    }
    unawaited(_readLocal(ticket));
    final result = await _getRecap(state.month);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) {
        if (silent && state.recap != null) return;
        emit(
          state.copyWith(
            status: HrPresenceRecapStatus.failure,
            failure: failure,
          ),
        );
      },
      (recap) => emit(
        state.copyWith(status: HrPresenceRecapStatus.ready, recap: recap),
      ),
    );
  }

  /// Le verrou du mois et les pointages non envoyés : la tablette seule.
  Future<void> _readLocal(int ticket) async {
    final month = state.month;
    final from = SchoolDayCalendar.firstOf(month);
    final to = SchoolDayCalendar.daysOf(month).last;
    final local = await _loadLocal(from: from, to: to);
    final count = await _countUnsynced(from: from, to: to);
    if (isClosed || ticket != _ticket) return;
    emit(
      state.copyWith(
        localLock: local.fold(
          (_) => state.localLock,
          (s) => s.monthLock(month),
        ),
        unsynced: count.fold((_) => state.unsynced, (n) => n),
      ),
    );
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}

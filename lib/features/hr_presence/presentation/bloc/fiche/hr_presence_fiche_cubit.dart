import 'dart:async';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/features/hr_presence/domain/services/hr_presence_day_check.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

export 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_state.dart';

/// La fiche individuelle d'un agent (spec §12) : son mois (route 2) ou son
/// année scolaire mois par mois (route 3). Une réponse dépassée est jetée.
class HrPresenceFicheCubit extends Cubit<HrPresenceFicheState> {
  final GetHrAttendanceAgentMonthUseCase _getMonth;
  final GetHrAttendanceAgentYearUseCase _getYear;
  final StaffSnapshotSource _source;
  final LoadStaffAttendanceUseCase? _loadAttendance;
  int _ticket = 0;
  int _localTicket = 0;
  void Function()? _unwatch;

  HrPresenceFicheCubit({
    required GetHrAttendanceAgentMonthUseCase getMonth,
    required GetHrAttendanceAgentYearUseCase getYear,
    required StaffSnapshotSource source,
    LoadStaffAttendanceUseCase? loadAttendance,
    required HrPresenceFicheArgs args,
    DateTime Function() now = DateTime.now,
  }) : _getMonth = getMonth,
       _getYear = getYear,
       _source = source,
       _loadAttendance = loadAttendance,
       super(_initial(args, now()));

  static HrPresenceFicheState _initial(HrPresenceFicheArgs args, DateTime now) {
    final current = SchoolDayCalendar.monthOf(
      // Le mois de l'école, comme le serveur : pas celui de la tablette.
      SchoolDayCalendar.dayOf(SchoolTime.today(now)),
    );
    final yearStart = args.yearStart;
    final first = yearStart == null
        ? null
        : SchoolDayCalendar.monthOf(SchoolDayCalendar.dayOf(yearStart));
    final asked = args.month;
    var month = asked != null && SchoolDayCalendar.isDay('$asked-01')
        ? asked
        : current;
    if (month.compareTo(current) > 0) month = current;
    if (first != null && month.compareTo(first) < 0) month = first;
    return HrPresenceFicheState(
      agentId: args.agentId,
      yearly: args.yearly,
      month: month,
      currentMonth: current,
      firstMonth: first,
    );
  }

  Future<void> load() async {
    unawaited(_readMembers());
    await _read();
  }

  Future<void> setYearly(bool yearly) {
    if (yearly == state.yearly) return Future.value();
    emit(state.copyWith(yearly: yearly));
    return _read();
  }

  Future<void> stepMonth(int direction) {
    if (direction < 0 && !state.canStepBack) return Future.value();
    final month = SchoolDayCalendar.addMonths(state.month, direction);
    if (month.compareTo(state.currentMonth) > 0) return Future.value();
    emit(state.copyWith(month: month));
    return _read();
  }

  Future<void> goCurrentMonth() {
    if (state.isCurrentMonth && !state.yearly) return Future.value();
    emit(state.copyWith(month: state.currentMonth, yearly: false));
    return _read();
  }

  /// Depuis la vue annuelle ou le sélecteur : la vue mensuelle de ce mois.
  Future<void> openMonth(String month) {
    if (month == state.month && !state.yearly) return Future.value();
    emit(state.copyWith(month: month, yearly: false));
    return _read();
  }

  Future<void> openAgent(String agentId) {
    if (agentId == state.agentId) return Future.value();
    emit(state.copyWith(agentId: agentId, localDays: const {}));
    return _read();
  }

  Future<void> retry() => _read();

  /// Un jour corrigé depuis la fiche : la ligne que la tablette vient
  /// d'écrire. Le calendrier la montre tout de suite ; la fiche se relit du
  /// serveur à chaque synchro, jusqu'à ce qu'il dise la même chose.
  void noteLocalDay(String day, StaffAttendanceRecord? record) {
    emit(state.copyWith(localDays: {...state.localDays, day: record}));
    _unwatch ??= _source.watch(() => unawaited(_reread()));
    unawaited(_readLocal());
  }

  /// Le verrou du mois et les pointages de l'agent pas encore envoyés, sur la
  /// portée affichée — lus sur la tablette, sans réseau.
  Future<void> _readLocal() async {
    final load = _loadAttendance;
    if (load == null) return;
    final ticket = ++_localTicket;
    final first = state.yearly
        ? state.firstMonth ?? state.currentMonth
        : state.month;
    final last = state.yearly ? state.currentMonth : state.month;
    final result = await load(
      from: SchoolDayCalendar.firstOf(first),
      to: SchoolDayCalendar.daysOf(last).last,
    );
    if (isClosed || ticket != _localTicket) return;
    result.fold((_) => emit(state.copyWith(local: null)), (snapshot) {
      final records = snapshot.records[state.agentId]?.values ?? const [];
      emit(
        state.copyWith(
          local: (
            monthClosed: !state.yearly && snapshot.isMonthClosed(state.month),
            unsent: records
                .where((r) => r.syncState != RecordSyncState.synced)
                .length,
          ),
        ),
      );
    });
  }

  /// Relecture **silencieuse** du mois : jamais de squelette, un échec garde
  /// l'écran. Les jours que le serveur a rattrapés quittent la tablette.
  Future<void> _reread() async {
    if (isClosed || state.yearly || state.localDays.isEmpty) return;
    final ticket = ++_ticket;
    final result = await _getMonth(state.agentId, month: state.month);
    if (isClosed || ticket != _ticket) return;
    result.fold((_) {}, (data) {
      final served = {for (final day in data.days) day.date: day};
      emit(
        state.copyWith(
          monthData: data,
          localDays: {
            for (final MapEntry(key: day, value: local)
                in state.localDays.entries)
              if (!_caughtUp(served[day], local)) day: local,
          },
        ),
      );
    });
  }

  /// Le serveur dit-il déjà ce que la tablette a écrit ?
  static bool _caughtUp(HrAttendanceDay? server, StaffAttendanceRecord? local) {
    if (server == null) return false;
    if (local == null) return server.status == PresenceStatus.none;
    return HrPresenceDayCheck.matches(server, local);
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }

  Future<void> _read() async {
    final ticket = ++_ticket;
    unawaited(_readLocal());
    emit(
      state.copyWith(
        status: HrPresenceFicheStatus.loading,
        monthData: null,
        yearData: null,
        failure: null,
      ),
    );
    if (state.yearly) {
      final result = await _getYear(state.agentId);
      if (isClosed || ticket != _ticket) return;
      result.fold(
        _fail,
        (data) => emit(
          state.copyWith(status: HrPresenceFicheStatus.ready, yearData: data),
        ),
      );
      return;
    }
    final result = await _getMonth(state.agentId, month: state.month);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      _fail,
      (data) => emit(
        state.copyWith(status: HrPresenceFicheStatus.ready, monthData: data),
      ),
    );
  }

  void _fail(Failure failure) => emit(
    state.copyWith(status: HrPresenceFicheStatus.failure, failure: failure),
  );

  Future<void> _readMembers() async {
    final result = await _source.read();
    if (isClosed) return;
    result.fold((_) {}, (file) => emit(state.copyWith(members: file.members)));
  }
}

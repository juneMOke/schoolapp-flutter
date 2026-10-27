import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

enum HrPresenceFicheStatus { loading, ready, failure }

const Object _undefined = Object();

/// Ce que l'adresse d'une fiche donne à son cubit.
typedef HrPresenceFicheArgs = ({
  String agentId,
  bool yearly,
  String? month,
  DateTime? yearStart,
});

class HrPresenceFicheState extends Equatable {
  final String agentId;
  final bool yearly;

  /// `AAAA-MM` de la vue mensuelle — gardé en vue annuelle.
  final String month;
  final String currentMonth;
  final String? firstMonth;
  final HrPresenceFicheStatus status;
  final HrAttendanceAgentMonth? monthData;
  final HrAttendanceAgentYear? yearData;
  final Failure? failure;
  final List<StaffMember> members;

  const HrPresenceFicheState({
    required this.agentId,
    required this.month,
    required this.currentMonth,
    this.yearly = false,
    this.firstMonth,
    this.status = HrPresenceFicheStatus.loading,
    this.monthData,
    this.yearData,
    this.failure,
    this.members = const [],
  });

  bool get isCurrentMonth => month == currentMonth;

  bool get canStepBack {
    final first = firstMonth;
    return first == null || month.compareTo(first) > 0;
  }

  HrPresenceFicheState copyWith({
    String? agentId,
    bool? yearly,
    String? month,
    HrPresenceFicheStatus? status,
    Object? monthData = _undefined,
    Object? yearData = _undefined,
    Object? failure = _undefined,
    List<StaffMember>? members,
  }) => HrPresenceFicheState(
    agentId: agentId ?? this.agentId,
    yearly: yearly ?? this.yearly,
    month: month ?? this.month,
    currentMonth: currentMonth,
    firstMonth: firstMonth,
    status: status ?? this.status,
    monthData: identical(monthData, _undefined)
        ? this.monthData
        : monthData as HrAttendanceAgentMonth?,
    yearData: identical(yearData, _undefined)
        ? this.yearData
        : yearData as HrAttendanceAgentYear?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    members: members ?? this.members,
  );

  @override
  List<Object?> get props => [
    agentId,
    yearly,
    month,
    currentMonth,
    firstMonth,
    status,
    monthData,
    yearData,
    failure,
    members,
  ];
}

/// La fiche individuelle d'un agent (spec §12) : son mois (route 2) ou son
/// année scolaire mois par mois (route 3). Une réponse dépassée est jetée.
class HrPresenceFicheCubit extends Cubit<HrPresenceFicheState> {
  final GetHrAttendanceAgentMonthUseCase _getMonth;
  final GetHrAttendanceAgentYearUseCase _getYear;
  final StaffSnapshotSource _source;
  int _ticket = 0;

  HrPresenceFicheCubit({
    required GetHrAttendanceAgentMonthUseCase getMonth,
    required GetHrAttendanceAgentYearUseCase getYear,
    required StaffSnapshotSource source,
    required HrPresenceFicheArgs args,
    DateTime Function() now = DateTime.now,
  }) : _getMonth = getMonth,
       _getYear = getYear,
       _source = source,
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
    emit(state.copyWith(agentId: agentId));
    return _read();
  }

  Future<void> retry() => _read();

  Future<void> _read() async {
    final ticket = ++_ticket;
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

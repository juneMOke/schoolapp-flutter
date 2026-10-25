import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

enum HrPresenceAgentMonthStatus { loading, ready, failure }

const Object _undefined = Object();

class HrPresenceAgentMonthState extends Equatable {
  final String agentId;

  /// `AAAA-MM`.
  final String month;

  /// Le mois en cours `AAAA-MM` : on ne va pas au-delà.
  final String currentMonth;

  /// Le mois de la rentrée, si l'année est connue : on ne remonte pas avant.
  final String? firstMonth;
  final HrPresenceAgentMonthStatus status;
  final HrAttendanceAgentMonth? data;
  final Failure? failure;

  /// Les agents du fichier local, pour passer de l'un à l'autre.
  final List<StaffMember> members;

  const HrPresenceAgentMonthState({
    required this.agentId,
    required this.month,
    required this.currentMonth,
    this.firstMonth,
    this.status = HrPresenceAgentMonthStatus.loading,
    this.data,
    this.failure,
    this.members = const [],
  });

  bool get isCurrentMonth => month == currentMonth;

  bool get canStepBack {
    final first = firstMonth;
    return first == null || month.compareTo(first) > 0;
  }

  HrPresenceAgentMonthState copyWith({
    String? agentId,
    String? month,
    HrPresenceAgentMonthStatus? status,
    Object? data = _undefined,
    Object? failure = _undefined,
    List<StaffMember>? members,
  }) => HrPresenceAgentMonthState(
    agentId: agentId ?? this.agentId,
    month: month ?? this.month,
    currentMonth: currentMonth,
    firstMonth: firstMonth,
    status: status ?? this.status,
    data: identical(data, _undefined)
        ? this.data
        : data as HrAttendanceAgentMonth?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    members: members ?? this.members,
  );

  @override
  List<Object?> get props => [
    agentId,
    month,
    currentMonth,
    firstMonth,
    status,
    data,
    failure,
    members,
  ];
}

/// Le mois d'un agent, lu au serveur (route 2) : le détail du tableau de bord
/// et la vue mensuelle de la fiche. Changer d'agent ou de mois montre le
/// squelette ; une réponse dépassée est jetée.
class HrPresenceAgentMonthCubit extends Cubit<HrPresenceAgentMonthState> {
  final GetHrAttendanceAgentMonthUseCase _getMonth;
  final StaffSnapshotSource _source;
  int _ticket = 0;

  HrPresenceAgentMonthCubit({
    required GetHrAttendanceAgentMonthUseCase getMonth,
    required StaffSnapshotSource source,
    required String agentId,
    String? month,
    DateTime? yearStart,
    DateTime Function() now = DateTime.now,
  }) : _getMonth = getMonth,
       _source = source,
       super(_initial(agentId, month, yearStart, now()));

  static HrPresenceAgentMonthState _initial(
    String agentId,
    String? month,
    DateTime? yearStart,
    DateTime now,
  ) {
    final current = SchoolDayCalendar.monthOf(
      // Le mois de l'école, comme le serveur : pas celui de la tablette.
      SchoolDayCalendar.dayOf(SchoolTime.today(now)),
    );
    final first = yearStart == null
        ? null
        : SchoolDayCalendar.monthOf(SchoolDayCalendar.dayOf(yearStart));
    var asked = month != null && SchoolDayCalendar.isDay('$month-01')
        ? month
        : current;
    // Ni au-delà du mois en cours, ni avant la rentrée.
    if (asked.compareTo(current) > 0) asked = current;
    if (first != null && asked.compareTo(first) < 0) asked = first;
    return HrPresenceAgentMonthState(
      agentId: agentId,
      month: asked,
      currentMonth: current,
      firstMonth: first,
    );
  }

  Future<void> load() async {
    unawaited(_readMembers());
    await _read();
  }

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
        status: HrPresenceAgentMonthStatus.loading,
        data: null,
        failure: null,
      ),
    );
    final result = await _getMonth(state.agentId, month: state.month);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HrPresenceAgentMonthStatus.failure,
          failure: failure,
        ),
      ),
      (data) => emit(
        state.copyWith(status: HrPresenceAgentMonthStatus.ready, data: data),
      ),
    );
  }

  /// Le sélecteur se contente du fichier local : un échec le laisse vide.
  Future<void> _readMembers() async {
    final result = await _source.read();
    if (isClosed) return;
    result.fold((_) {}, (file) => emit(state.copyWith(members: file.members)));
  }
}

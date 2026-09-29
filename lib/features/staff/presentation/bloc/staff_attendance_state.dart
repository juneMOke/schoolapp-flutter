import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_view_mode.dart';

/// Les trois onglets du Pointage.
enum StaffAttendanceTab { register, agentMonth, recap }

/// Premier chargement, prêt, ou panne de lecture. Comme le fichier du
/// personnel, jamais d'état « jamais téléchargé » : l'écran s'ouvre sur ce que
/// la tablette connaît et le dit par un bandeau.
enum StaffAttendanceLoad { loading, ready, failure }

class StaffAttendanceState extends Equatable {
  final StaffAttendanceLoad load;
  final StaffAttendanceSnapshot snapshot;
  final StaffAttendanceTab tab;

  /// Aujourd'hui, `YYYY-MM-DD` : ni le registre ni les mois ne vont au-delà.
  final String today;

  /// Le jour du registre.
  final String day;

  /// Le mois partagé par la fiche et le récapitulatif, `YYYY-MM`.
  final String month;

  final StaffDayQuery dayQuery;
  final StaffViewMode viewMode;
  final StaffRecapQuery recapQuery;

  /// L'agent de la fiche mensuelle ; `null` = le premier du fichier.
  final String? agentId;

  final StaffAttendanceNotice? notice;
  final Failure? failure;

  const StaffAttendanceState({
    required this.load,
    required this.snapshot,
    required this.tab,
    required this.today,
    required this.day,
    required this.month,
    required this.dayQuery,
    required this.viewMode,
    required this.recapQuery,
    this.agentId,
    this.notice,
    this.failure,
  });

  factory StaffAttendanceState.initial({
    required String today,
    required String day,
  }) => StaffAttendanceState(
    load: StaffAttendanceLoad.loading,
    snapshot: StaffAttendanceSnapshot.empty,
    tab: StaffAttendanceTab.register,
    today: today,
    day: day,
    month: today.substring(0, 7),
    dayQuery: StaffDayQuery.none,
    viewMode: StaffViewMode.grid,
    recapQuery: StaffRecapQuery.none,
  );

  /// Le dernier jour ouvré jusqu'à aujourd'hui : aujourd'hui en semaine, le
  /// vendredi le week-end. C'est là que ramène « Aujourd'hui ».
  String get lastWorkDay => StaffWorkCalendar.isWeekday(today)
      ? today
      : StaffWorkCalendar.stepWorkDay(today, -1);

  bool get isToday => day == lastWorkDay;

  StaffDayRegister get register =>
      StaffDayRegister.build(snapshot, day: day, query: dayQuery);

  StaffMonthRecap get recap => StaffMonthRecap.build(
    snapshot,
    month: month,
    today: today,
    query: recapQuery,
  );

  StaffAttendanceState copyWith({
    StaffAttendanceLoad? load,
    StaffAttendanceSnapshot? snapshot,
    StaffAttendanceTab? tab,
    String? today,
    String? day,
    String? month,
    StaffDayQuery? dayQuery,
    StaffViewMode? viewMode,
    StaffRecapQuery? recapQuery,
    String? Function()? agentId,
    StaffAttendanceNotice? notice,
    Failure? failure,
    bool clearFailure = false,
  }) => StaffAttendanceState(
    load: load ?? this.load,
    snapshot: snapshot ?? this.snapshot,
    tab: tab ?? this.tab,
    today: today ?? this.today,
    day: day ?? this.day,
    month: month ?? this.month,
    dayQuery: dayQuery ?? this.dayQuery,
    viewMode: viewMode ?? this.viewMode,
    recapQuery: recapQuery ?? this.recapQuery,
    agentId: agentId == null ? this.agentId : agentId(),
    notice: notice ?? this.notice,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    load,
    snapshot,
    tab,
    today,
    day,
    month,
    dayQuery,
    viewMode,
    recapQuery,
    agentId,
    notice,
    failure,
  ];
}

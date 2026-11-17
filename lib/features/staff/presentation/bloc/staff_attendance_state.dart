import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';

/// Premier chargement, prêt, ou panne de lecture. Comme le fichier du
/// personnel, jamais d'état « jamais téléchargé » : l'écran s'ouvre sur ce que
/// la tablette connaît et le dit par un bandeau.
enum StaffAttendanceLoad { loading, ready, failure }

class StaffAttendanceState extends Equatable {
  final StaffAttendanceLoad load;
  final StaffAttendanceSnapshot snapshot;

  /// Aujourd'hui, `YYYY-MM-DD` : le registre ne va pas au-delà.
  final String today;

  /// Le jour du registre.
  final String day;

  final StaffDayQuery dayQuery;
  final CollectionViewMode viewMode;

  final StaffAttendanceNotice? notice;
  final Failure? failure;

  const StaffAttendanceState({
    required this.load,
    required this.snapshot,
    required this.today,
    required this.day,
    required this.dayQuery,
    required this.viewMode,
    this.notice,
    this.failure,
  });

  factory StaffAttendanceState.initial({
    required String today,
    required String day,
  }) => StaffAttendanceState(
    load: StaffAttendanceLoad.loading,
    snapshot: StaffAttendanceSnapshot.empty,
    today: today,
    day: day,
    dayQuery: StaffDayQuery.none,
    // La liste d'abord, comme les autres tables de l'application.
    viewMode: CollectionViewMode.list,
  );

  /// Le dernier jour ouvré jusqu'à aujourd'hui : aujourd'hui en semaine, le
  /// vendredi le week-end. C'est là que ramène « Aujourd'hui ».
  String get lastWorkDay => SchoolDayCalendar.isWeekday(today)
      ? today
      : SchoolDayCalendar.stepWorkDay(today, -1);

  bool get isToday => day == lastWorkDay;

  /// Le premier jour que le registre peut montrer : le début de l'année
  /// scolaire, quand il est connu.
  String? get firstDay => snapshot.schoolYear?.start;

  /// Le registre peut-il reculer d'un jour ouvré ?
  bool get canStepBack {
    final first = firstDay;
    return first == null ||
        SchoolDayCalendar.stepWorkDay(day, -1).compareTo(first) >= 0;
  }

  StaffDayRegister get register =>
      StaffDayRegister.build(snapshot, day: day, query: dayQuery);

  StaffAttendanceState copyWith({
    StaffAttendanceLoad? load,
    StaffAttendanceSnapshot? snapshot,
    String? today,
    String? day,
    StaffDayQuery? dayQuery,
    CollectionViewMode? viewMode,
    StaffAttendanceNotice? notice,
    Failure? failure,
    bool clearFailure = false,
  }) => StaffAttendanceState(
    load: load ?? this.load,
    snapshot: snapshot ?? this.snapshot,
    today: today ?? this.today,
    day: day ?? this.day,
    dayQuery: dayQuery ?? this.dayQuery,
    viewMode: viewMode ?? this.viewMode,
    notice: notice ?? this.notice,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    load,
    snapshot,
    today,
    day,
    dayQuery,
    viewMode,
    notice,
    failure,
  ];
}

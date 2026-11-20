import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_calendar_reader.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

enum ClassTimetableStatus { loading, ready, failure }

/// Semaine ou Jour (EDT-R12) ; `null` : la vue par défaut selon la largeur.
enum ClassTimetableMode { week, day }

class ClassTimetableState extends Equatable {
  final ClassTimetableStatus status;
  final Failure? failure;
  final List<TimetableClassOption> options;
  final String? classroomId;
  final ClassTimetableView? view;
  final ClassTimetableMode? mode;
  final Weekday? day;

  /// Le lundi de la semaine datée affichée (R17) ; `null` : cette semaine.
  final DateTime? week;

  /// Ce que le calendrier publié dit de cette semaine, pour cette classe.
  final ClassCalendarWeek? calendar;

  /// Un geste est en cours (commencer, copier, abandonner, publier) : ses
  /// boutons attendent, un second appui ne le relance pas (I19).
  final bool busy;

  const ClassTimetableState({
    this.status = ClassTimetableStatus.loading,
    this.failure,
    this.options = const [],
    this.classroomId,
    this.view,
    this.mode,
    this.day,
    this.week,
    this.calendar,
    this.busy = false,
  });

  TimetableClassOption? get selected {
    for (final o in options) {
      if (o.classroomId == classroomId) return o;
    }
    return null;
  }

  ClassTimetableState copyWith({
    ClassTimetableStatus? status,
    Failure? failure,
    List<TimetableClassOption>? options,
    String? classroomId,
    bool clearClassroom = false,
    ClassTimetableView? view,
    bool clearView = false,
    ClassTimetableMode? mode,
    bool clearMode = false,
    Weekday? day,
    bool clearDay = false,
    DateTime? week,
    bool clearWeek = false,
    ClassCalendarWeek? calendar,
    bool clearCalendar = false,
    bool? busy,
  }) => ClassTimetableState(
    status: status ?? this.status,
    failure: failure,
    options: options ?? this.options,
    classroomId: clearClassroom ? null : (classroomId ?? this.classroomId),
    view: clearView ? null : (view ?? this.view),
    mode: clearMode ? null : (mode ?? this.mode),
    day: clearDay ? null : (day ?? this.day),
    week: clearWeek ? null : (week ?? this.week),
    calendar: clearCalendar ? null : (calendar ?? this.calendar),
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [
    status,
    failure,
    options,
    classroomId,
    view,
    mode,
    day,
    week,
    calendar,
    busy,
  ];
}

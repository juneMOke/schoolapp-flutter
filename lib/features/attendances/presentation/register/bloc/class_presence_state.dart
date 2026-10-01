import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_notice.dart';

/// Aucune classe choisie, lecture en cours, prête, ou panne de lecture.
enum ClassPresenceLoad { noClass, loading, ready, failure }

class ClassPresenceState extends Equatable {
  final ClassPresenceLoad load;
  final String? academicYearId;

  /// Les bornes de l'année scolaire, quand elles sont connues.
  final SchoolYearBounds? schoolYear;
  final ClassPresenceClassroom? classroom;

  /// L'appel du jour affiché ; `null` avant la première lecture.
  final ClassPresenceDay? presenceDay;

  /// Aujourd'hui, `YYYY-MM-DD` : le registre ne va pas au-delà.
  final String today;

  /// Le jour du registre.
  final String day;
  final ClassDayQuery dayQuery;
  final CollectionViewMode viewMode;
  final ClassPresenceNotice? notice;
  final Failure? failure;

  const ClassPresenceState({
    required this.load,
    required this.today,
    required this.day,
    this.academicYearId,
    this.schoolYear,
    this.classroom,
    this.presenceDay,
    this.dayQuery = ClassDayQuery.none,
    this.viewMode = CollectionViewMode.grid,
    this.notice,
    this.failure,
  });

  /// Le dernier jour de classe jusqu'à aujourd'hui : aujourd'hui en semaine,
  /// le vendredi le week-end. C'est là que ramène « Aujourd'hui ».
  static String lastSchoolDayOf(String today) =>
      SchoolDayCalendar.isWeekday(today)
      ? today
      : SchoolDayCalendar.stepWorkDay(today, -1);

  bool get isToday => day == lastSchoolDayOf(today);

  /// Le registre peut-il reculer d'un jour de classe ? Pas avant la rentrée.
  bool get canStepBack {
    final first = schoolYear?.start;
    return first == null ||
        SchoolDayCalendar.stepWorkDay(day, -1).compareTo(first) >= 0;
  }

  /// Le registre filtré du jour ; `null` avant la première lecture.
  ClassDayRegister? get register {
    final presenceDay = this.presenceDay;
    return presenceDay == null
        ? null
        : ClassDayRegister.build(presenceDay, dayQuery);
  }

  ClassPresenceState copyWith({
    ClassPresenceLoad? load,
    String? academicYearId,
    SchoolYearBounds? schoolYear,
    ClassPresenceClassroom? classroom,
    ClassPresenceDay? Function()? presenceDay,
    String? today,
    String? day,
    ClassDayQuery? dayQuery,
    CollectionViewMode? viewMode,
    ClassPresenceNotice? notice,
    Failure? failure,
    bool clearFailure = false,
  }) => ClassPresenceState(
    load: load ?? this.load,
    academicYearId: academicYearId ?? this.academicYearId,
    schoolYear: schoolYear ?? this.schoolYear,
    classroom: classroom ?? this.classroom,
    presenceDay: presenceDay == null ? this.presenceDay : presenceDay(),
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
    academicYearId,
    schoolYear,
    classroom,
    presenceDay,
    today,
    day,
    dayQuery,
    viewMode,
    notice,
    failure,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/features/attendances/domain/services/student_presence_month.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_notice.dart';

/// Aucune classe choisie, lecture en cours, prête, ou panne de lecture.
enum ClassPresenceLoad { noClass, loading, ready, failure }

/// Les trois onglets de l'appel.
enum ClassPresenceTab { register, studentMonth, recap }

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
  final ClassPresenceTab tab;

  /// Le mois partagé par la fiche et le récapitulatif, `YYYY-MM`.
  final String month;

  /// Les appels du mois ; `null` tant qu'ils ne sont pas lus.
  final ClassPresenceMonth? monthData;

  /// La dernière lecture du mois a échoué (la fiche et le récapitulatif
  /// l'affichent au lieu d'attendre).
  final bool monthFailed;

  /// L'élève de la fiche mensuelle ; `null` = le premier de la classe.
  final String? studentId;
  final ClassRecapQuery recapQuery;
  final ClassPresenceNotice? notice;
  final Failure? failure;

  const ClassPresenceState({
    required this.load,
    required this.today,
    required this.day,
    required this.month,
    this.academicYearId,
    this.schoolYear,
    this.classroom,
    this.presenceDay,
    this.dayQuery = ClassDayQuery.none,
    this.viewMode = CollectionViewMode.grid,
    this.tab = ClassPresenceTab.register,
    this.monthData,
    this.monthFailed = false,
    this.studentId,
    this.recapQuery = ClassRecapQuery.none,
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

  bool get isCurrentMonth => month == today.substring(0, 7);

  /// La fiche et le récapitulatif peuvent-ils reculer d'un mois ? Pas avant
  /// le mois de la rentrée.
  bool get canStepMonthBack {
    final first = schoolYear?.start;
    return first == null || month.compareTo(first.substring(0, 7)) > 0;
  }

  /// La fiche mensuelle de l'élève choisi (ou du premier) ; `null` sans
  /// mois lu ou sans élève.
  StudentPresenceMonth? get studentMonth {
    final data = monthData;
    if (data == null || data.students.isEmpty) return null;
    final student = data.students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => data.students.first,
    );
    return StudentPresenceMonth.build(
      data,
      student,
      today: today,
      year: schoolYear,
    );
  }

  /// Le récapitulatif filtré du mois ; `null` sans mois lu.
  ClassMonthRecap? get recap {
    final data = monthData;
    return data == null
        ? null
        : ClassMonthRecap.build(
            data,
            today: today,
            query: recapQuery,
            year: schoolYear,
          );
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
    ClassPresenceTab? tab,
    String? month,
    ClassPresenceMonth? Function()? monthData,
    bool? monthFailed,
    String? Function()? studentId,
    ClassRecapQuery? recapQuery,
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
    tab: tab ?? this.tab,
    month: month ?? this.month,
    monthData: monthData == null ? this.monthData : monthData(),
    monthFailed: monthFailed ?? this.monthFailed,
    studentId: studentId == null ? this.studentId : studentId(),
    recapQuery: recapQuery ?? this.recapQuery,
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
    tab,
    month,
    monthData,
    monthFailed,
    studentId,
    recapQuery,
    notice,
    failure,
  ];
}

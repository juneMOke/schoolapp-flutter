import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// « Où en est l'année » (CAL-R14), calculé à l'écran.
class SchoolYearProgress extends Equatable {
  /// Semaine en cours, comptée depuis le lundi de la rentrée (1 = la première).
  final int week;

  /// Nombre de semaines de l'année.
  final int weekCount;

  /// La sous-période en cours pour le rythme demandé, `null` hors période.
  final CalendarElement? currentPeriod;

  /// Les éléments (hors périodes) qui couvrent aujourd'hui.
  final List<CalendarElement> happeningNow;

  /// Le prochain examen ou congé à venir, et dans combien de jours.
  final CalendarElement? nextDeadline;
  final int? daysUntilNextDeadline;

  const SchoolYearProgress({
    required this.week,
    required this.weekCount,
    required this.currentPeriod,
    required this.happeningNow,
    required this.nextDeadline,
    required this.daysUntilNextDeadline,
  });

  /// Part écoulée, de 0 à 1.
  double get ratio => weekCount == 0 ? 0 : (week / weekCount).clamp(0, 1);

  /// `null` hors de l'année scolaire : ni semaine, ni période, ni échéance.
  ///
  /// [rhythm] choisit le jeu de périodes (A1) ; `null` accepte toute période.
  static SchoolYearProgress? compute({
    required DateTime startDate,
    required DateTime endDate,
    required DateTime today,
    required List<CalendarElement> elements,
    PeriodRhythm? rhythm,
  }) {
    final day = CalendarDays.of(today);
    if (!CalendarDays.within(day, startDate, endDate)) return null;
    final firstMonday = CalendarDays.mondayOf(startDate);
    final week = CalendarDays.between(firstMonday, day) ~/ 7 + 1;
    final weekCount =
        CalendarDays.between(firstMonday, CalendarDays.mondayOf(endDate)) ~/ 7 +
        1;

    CalendarElement? period;
    final now = <CalendarElement>[];
    CalendarElement? next;
    for (final element in elements) {
      if (element.nature == CalendarNature.period) {
        final rightRhythm = rhythm == null || element.rhythm == rhythm;
        if (rightRhythm &&
            element.covers(day) &&
            element.subPeriodOrder != null) {
          period = element;
        }
        continue;
      }
      if (element.covers(day)) now.add(element);
      final isDeadline =
          element.nature == CalendarNature.exam ||
          element.nature == CalendarNature.holidayBreak;
      if (isDeadline && element.startDate.isAfter(day)) {
        if (next == null || element.startDate.isBefore(next.startDate)) {
          next = element;
        }
      }
    }
    return SchoolYearProgress(
      week: week,
      weekCount: weekCount,
      currentPeriod: period,
      happeningNow: now,
      nextDeadline: next,
      daysUntilNextDeadline: next == null
          ? null
          : CalendarDays.between(day, next.startDate),
    );
  }

  @override
  List<Object?> get props => [
    week,
    weekCount,
    currentPeriod,
    happeningNow,
    nextDeadline,
    daysUntilNextDeadline,
  ];
}

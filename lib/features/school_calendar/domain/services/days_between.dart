import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// Ce qu'un jour porte pour une classe (ou pour toute l'école).
class CalendarDay extends Equatable {
  final DateTime date;

  /// Tous les éléments qui couvrent ce jour, périodes comprises, par priorité
  /// de nature ([DaysBetween.order]), puis date de début, puis id.
  final List<CalendarElement> elements;

  /// La nature qui colore la case (CAL-R15), `null` si aucune.
  final CalendarNature? topNature;

  const CalendarDay({
    required this.date,
    required this.elements,
    required this.topNature,
  });

  /// Pas de cours ce jour-là : un congé ou un jour férié concerne la classe
  /// (`noClasses` des vecteurs). [topNature] ne suffit pas : un examen peut
  /// primer sur un congé le même jour.
  bool get isClosed => elements.any(
    (e) =>
        e.nature == CalendarNature.publicHoliday ||
        e.nature == CalendarNature.holidayBreak,
  );

  @override
  List<Object?> get props => [date, elements, topNature];
}

/// Les jours d'un intervalle et ce qu'ils portent — la même fonction que
/// `CalendarPort.daysBetween` côté serveur (A15), tenue identique par les
/// vecteurs partagés `calendar/days-between-vectors.json` (lot V0).
///
/// Règles :
/// - un élément concerne la classe selon sa portée (K7, A2) ; sans [classroom],
///   tous les éléments comptent (vue de toute l'école) ;
/// - la couleur d'un jour est celle de l'élément le plus important, dans
///   l'ordre férié, examens, congés, interrogations, vie de l'école (CAL-R15) ;
///   une période ne colore jamais ;
/// - le samedi et le dimanche ne se colorent que pour un congé, un jour férié
///   ou un événement d'un seul jour.
class DaysBetween {
  const DaysBetween._();

  /// L'ordre d'importance de CAL-R15, du plus fort au plus faible.
  static const priority = [
    CalendarNature.publicHoliday,
    CalendarNature.exam,
    CalendarNature.holidayBreak,
    CalendarNature.assessment,
    CalendarNature.schoolLife,
  ];

  /// L'ordre des éléments d'un jour : [priority], puis les périodes.
  static const order = [...priority, CalendarNature.period];

  static int _compare(CalendarElement a, CalendarElement b) {
    final byNature = order.indexOf(a.nature).compareTo(order.indexOf(b.nature));
    if (byNature != 0) return byNature;
    final byStart = a.startDate.compareTo(b.startDate);
    return byStart != 0 ? byStart : a.id.compareTo(b.id);
  }

  static List<CalendarDay> compute({
    required DateTime from,
    required DateTime to,
    required List<CalendarElement> elements,
    ClassroomScopeKey? classroom,
  }) {
    final start = CalendarDays.of(from);
    final end = CalendarDays.of(to);
    final relevant = [
      for (final element in elements)
        if ((classroom == null || classroom.isConcernedBy(element.scope)) &&
            element.overlaps(start, end))
          element,
    ]..sort(_compare);
    final days = <CalendarDay>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = CalendarDays.addDays(day, 1)
    ) {
      final covering = [
        for (final element in relevant)
          if (element.covers(day)) element,
      ];
      days.add(
        CalendarDay(
          date: day,
          elements: covering,
          topNature: topNatureOf(day, covering),
        ),
      );
    }
    return days;
  }

  static CalendarNature? topNatureOf(
    DateTime day,
    List<CalendarElement> covering,
  ) {
    final weekend = CalendarDays.isWeekend(day);
    for (final nature in priority) {
      final colours = covering.any(
        (e) => e.nature == nature && (!weekend || _coloursWeekend(e)),
      );
      if (colours) return nature;
    }
    return null;
  }

  static bool _coloursWeekend(CalendarElement element) =>
      element.nature == CalendarNature.holidayBreak ||
      element.nature == CalendarNature.publicHoliday ||
      element.isSingleDay;
}

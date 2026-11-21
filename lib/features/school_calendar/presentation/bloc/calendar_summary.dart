import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_replacements.dart';

/// Les éléments montrés d'un calendrier : le cadre de son année, puis les
/// événements de l'école, remplacements résolus sur la liste entière ;
/// périodes du cadre limitées au [rhythm] effectif. Un remplacement refusé à
/// sa création reste montré, marqué, sans masquer l'élément national qu'il
/// visait ; une modification refusée masque toujours (le serveur garde la
/// version acceptée).
///
/// Une seule règle pour le calendrier ouvert et pour les cartes de la liste :
/// les deux comptent les mêmes éléments.
List<CalendarElement> resolveCalendarElements({
  required List<CalendarElement> national,
  required List<SchoolEventRecord> events,
  required PeriodRhythm? rhythm,
}) {
  final resolved = CalendarReplacements.resolveForDisplay(
    [...national, for (final record in events) record.element],
    inert: {
      for (final r in events)
        if (r.isRejectedCreation) r.element.id,
    },
  );
  return [
    for (final e in resolved)
      if (e.nature != CalendarNature.period ||
          rhythm == null ||
          e.rhythm == null ||
          e.rhythm == rhythm)
        e,
  ];
}

/// Ce qu'une carte ou le bandeau de la liste disent d'un calendrier (CAL D5) :
/// ses éléments montrés, nationaux, de l'école, à vérifier, par nature, et
/// les gestes encore sur l'appareil.
class CalendarSummary {
  final List<CalendarElement> elements;
  final int pendingCount;

  const CalendarSummary({required this.elements, this.pendingCount = 0});

  int get nationalCount => elements.where((e) => e.isNational).length;

  int get schoolCount => elements.where((e) => !e.isNational).length;

  int get toVerifyCount => elements.where((e) => e.toVerify).length;

  /// Le nombre d'éléments de chaque nature, périodes comprises.
  int countOf(CalendarNature nature) =>
      elements.where((e) => e.nature == nature).length;
}

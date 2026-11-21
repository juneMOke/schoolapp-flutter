import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// Les périodes que montre un calendrier ouvert : le niveau le plus fin
/// (spec §4.6 D, « la période occupe toujours le premier couloir »).
///
/// Le cadre national publie, pour un rythme, ses périodes (« Premier
/// semestre ») et leurs sous-périodes (« 1re période », « 2e période »). Les
/// deux couvrent les mêmes jours : dessinées ensemble, elles prenaient deux
/// couloirs pleine largeur par semaine. Une période qui a des sous-périodes
/// s'efface donc derrière elles ; une période sans sous-période (rythme qui
/// n'en déclare pas) reste.
class CalendarPeriods {
  const CalendarPeriods._();

  /// [elements] sans les périodes que leurs sous-périodes remplacent ; les
  /// autres natures passent telles quelles, dans le même ordre.
  static List<CalendarElement> finest(List<CalendarElement> elements) {
    final subs = [
      for (final e in elements)
        if (e.nature == CalendarNature.period && e.subPeriodOrder != null) e,
    ];
    if (subs.isEmpty) return elements;
    return [
      for (final e in elements)
        if (!_hasSubPeriods(e, subs)) e,
    ];
  }

  static bool _hasSubPeriods(
    CalendarElement period,
    List<CalendarElement> subs,
  ) {
    if (period.nature != CalendarNature.period ||
        period.subPeriodOrder != null) {
      return false;
    }
    return subs.any(
      (s) =>
          s.rhythm == period.rhythm &&
          (period.periodOrder != null && s.periodOrder != null
              ? s.periodOrder == period.periodOrder
              : CalendarDays.within(
                  s.startDate,
                  period.startDate,
                  period.endDate,
                )),
    );
  }
}

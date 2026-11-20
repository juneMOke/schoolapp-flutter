import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// Un morceau de bande : un élément, sur une semaine, de la colonne
/// [startCol] à [endCol] incluses (0 = lundi), dans le couloir [lane].
class MonthBand extends Equatable {
  final CalendarElement element;
  final int startCol;
  final int endCol;
  final int lane;

  /// La bande continue de la semaine précédente / continue la suivante :
  /// son bord n'est pas arrondi de ce côté.
  final bool continuesBefore;
  final bool continuesAfter;

  const MonthBand({
    required this.element,
    required this.startCol,
    required this.endCol,
    required this.lane,
    required this.continuesBefore,
    required this.continuesAfter,
  });

  @override
  List<Object?> get props => [element.id, startCol, endCol, lane];
}

/// Une rangée du mois : sept jours, lundi en premier.
class MonthWeek extends Equatable {
  final List<DateTime> days;
  final List<MonthBand> bands;

  /// Éléments qui ne tiennent pas dans les couloirs, par colonne.
  final List<int> hiddenByCol;

  const MonthWeek({
    required this.days,
    required this.bands,
    required this.hiddenByCol,
  });

  @override
  List<Object?> get props => [days, bands, hiddenByCol];
}

/// Disposition d'un mois en rangées de semaines et en couloirs (CAL §4.6 D) :
/// - un élément de plusieurs jours est une bande continue, coupée aux bords de
///   la semaine ;
/// - la période occupe toujours le premier couloir ;
/// - au plus [maxLanes] couloirs (4, ou 3 en compact) ; au-delà, « +n autres ».
class MonthLayout {
  const MonthLayout._();

  static List<MonthWeek> compute({
    required int year,
    required int month,
    required List<CalendarElement> elements,
    required int maxLanes,
  }) {
    final first = DateTime.utc(year, month, 1);
    final last = DateTime.utc(year, month + 1, 0);
    final weeks = <MonthWeek>[];
    for (
      var monday = CalendarDays.mondayOf(first);
      !monday.isAfter(last);
      monday = CalendarDays.addDays(monday, 7)
    ) {
      weeks.add(_week(monday, elements, maxLanes));
    }
    return weeks;
  }

  static MonthWeek _week(
    DateTime monday,
    List<CalendarElement> elements,
    int maxLanes,
  ) {
    final sunday = CalendarDays.addDays(monday, 6);
    final days = [for (var i = 0; i < 7; i++) CalendarDays.addDays(monday, i)];
    final inWeek = [
      for (final e in elements)
        if (e.overlaps(monday, sunday)) e,
    ]..sort(_order);

    // Un couloir = la liste des colonnes déjà occupées.
    final lanes = <List<bool>>[];
    final bands = <MonthBand>[];
    final hidden = List<int>.filled(7, 0);
    for (final element in inWeek) {
      final start = element.startDate.isBefore(monday)
          ? 0
          : CalendarDays.between(monday, element.startDate);
      final end = element.endDate.isAfter(sunday)
          ? 6
          : CalendarDays.between(monday, element.endDate);
      var lane = 0;
      while (lane < lanes.length && !_free(lanes[lane], start, end)) {
        lane++;
      }
      if (lane >= maxLanes) {
        for (var col = start; col <= end; col++) {
          hidden[col]++;
        }
        continue;
      }
      if (lane == lanes.length) lanes.add(List<bool>.filled(7, false));
      for (var col = start; col <= end; col++) {
        lanes[lane][col] = true;
      }
      bands.add(
        MonthBand(
          element: element,
          startCol: start,
          endCol: end,
          lane: lane,
          continuesBefore: element.startDate.isBefore(monday),
          continuesAfter: element.endDate.isAfter(sunday),
        ),
      );
    }
    return MonthWeek(days: days, bands: bands, hiddenByCol: hidden);
  }

  static bool _free(List<bool> lane, int start, int end) {
    for (var col = start; col <= end; col++) {
      if (lane[col]) return false;
    }
    return true;
  }

  /// Périodes d'abord, puis par date de début, la plus longue d'abord, puis id.
  static int _order(CalendarElement a, CalendarElement b) {
    final aPeriod = a.nature == CalendarNature.period ? 0 : 1;
    final bPeriod = b.nature == CalendarNature.period ? 0 : 1;
    if (aPeriod != bPeriod) return aPeriod - bPeriod;
    final byStart = a.startDate.compareTo(b.startDate);
    if (byStart != 0) return byStart;
    final byLength = b.durationDays.compareTo(a.durationDays);
    return byLength != 0 ? byLength : a.id.compareTo(b.id);
  }
}

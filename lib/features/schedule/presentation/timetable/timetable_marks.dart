import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_calendar_reader.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_conflicts.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que dit le créneau actuel d'aujourd'hui (R11), pour le pavé « En
/// cours » : la séance en cours, la suivante, ou la période qui ferme le jour.
class TimetableNow {
  final ClassTimetableCell? current;
  final ClassTimetableCell? next;

  /// Le jour est fermé (férié, vacances) : la période qui le ferme.
  final CalendarElement? closedBy;

  const TimetableNow({this.current, this.next, this.closedBy});
}

/// Les marques de la grille, calculées sur l'appareil (EDT §4.6 D, R3, R4,
/// R11, R17) : des fonctions pures, testées sans écran.
class TimetableMarks {
  const TimetableMarks._();

  /// Les jours fermés de la semaine datée : en-tête « Jour férié » /
  /// « Vacances », et la période nommée.
  static Map<Weekday, ScheduleClosedDay> closedDays(
    ClassCalendarWeek? week,
    AppLocalizations l10n,
  ) => {
    for (final day in week?.days ?? const [])
      if (day.isClosed)
        if (CurrentSession.weekdayOf(day.date) case final weekday?)
          if (closingElement(day.elements) case final element?)
            weekday: ScheduleClosedDay(
              header: l10n.classTimetablePeriodKind(element.nature.wire),
              period: element.title,
            ),
  };

  /// L'élément qui ferme un jour : le férié avant les vacances.
  static CalendarElement? closingElement(List<CalendarElement> elements) {
    for (final nature in const [
      CalendarNature.publicHoliday,
      CalendarNature.holidayBreak,
    ]) {
      for (final e in elements) {
        if (e.nature == nature) return e;
      }
    }
    return null;
  }

  /// « En cours » et « Ensuite » à [wallClock] (heure de l'école), sur la
  /// version publiée ; `null` hors d'un jour de semaine.
  static TimetableNow? now(
    ClassTimetableView view,
    ClassCalendarWeek? week,
    DateTime wallClock,
  ) {
    final today = CurrentSession.weekdayOf(wallClock);
    if (today == null) return null;
    for (final day in week?.days ?? const []) {
      if (CurrentSession.weekdayOf(day.date) == today && day.isClosed) {
        return TimetableNow(closedBy: closingElement(day.elements));
      }
    }
    final cells = {
      for (final c in view.published)
        if (c.day == today && !c.isEmpty) c.id: c,
    };
    final state = CurrentSession.at(
      minuteOfDay: wallClock.hour * 60 + wallClock.minute,
      sessions: [
        for (final c in cells.values) DaySession(id: c.id, range: c.range),
      ],
    );
    return TimetableNow(
      current: cells[state.current?.id],
      next: cells[state.next?.id],
    );
  }

  /// Les séances du brouillon « Hors programme » (R3) : un cours retiré du
  /// programme après coup. Elles doivent être libérées avant de publier.
  static Set<String> outOfProgramme(ClassTimetableView view) {
    final known = {for (final c in view.programme) c.coursId};
    return {
      for (final c in view.draft)
        if (c.coursId case final id? when !known.contains(id)) c.id,
    };
  }

  /// Les cases refusées par le serveur (R18).
  static Set<String> rejected(ClassTimetableView view) => {
    for (final c in view.draft)
      if (c.syncState == RecordSyncState.failed) c.id,
  };

  /// Les alertes d'un brouillon, une raison par séance : conflit d'abord,
  /// puis hors programme, puis refus.
  static Map<String, String> draftAlerts(
    ClassTimetableView view,
    AppLocalizations l10n,
  ) {
    final alerts = <String, String>{};
    for (final id in rejected(view)) {
      alerts[id] = l10n.classTimetableRejectedCell;
    }
    for (final id in outOfProgramme(view)) {
      alerts[id] = l10n.classTimetableOutOfProgramme;
    }
    DraftConflicts.of(view).forEach((id, booking) {
      alerts[id] = l10n.classTimetableConflictWith(booking.classroomLabel);
    });
    return alerts;
  }
}

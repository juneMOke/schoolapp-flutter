import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// La semaine d'une classe, mise dans la forme que lisent la grille et la vue
/// Jour de Cours ▸ Emploi du temps (extensions, EDT §4.6 D et E).
///
/// Deux écarts à la vue enseignant :
/// - la seconde ligne d'une séance porte l'**enseignant** (et rien pour un
///   cours sans enseignant, R3), pas la classe ;
/// - le samedi est toujours une colonne (R1), et la récréation de la grille
///   une bande.
class ClassWeekBuilder {
  const ClassWeekBuilder._();

  static WeeklyTimetable build(
    ClassTimetableView view,
    List<ClassTimetableCell> cells,
  ) {
    final byKey = {
      for (final c in cells)
        if (!c.isEmpty) '${c.slotId}|${c.day.wire}': c,
    };
    final slots = [...view.slots];
    final recess = view.grid?.recess;
    final recessTaken =
        recess != null &&
        slots.any((s) {
          final r = MinuteRange.fromClocks(s.startTime, s.endTime);
          return r != null && SlotOverlap.overlaps(r, recess);
        });
    if (recess != null && !recessTaken) {
      slots.add(
        TimeSlot(
          id: 'recess:${view.grid!.id}',
          order: -1,
          startTime: _clock(recess.startMinute),
          endTime: _clock(recess.endMinute),
          isBreak: true,
        ),
      );
    }
    slots.sort(TimeSlot.compareByTime);
    return WeeklyTimetable(
      academicYearId: view.header?.academicYearId ?? '',
      teacherId: null,
      classroomId: view.classroom.classroomId,
      days: Weekday.values,
      rows: [
        for (final slot in slots)
          TimetableRow(
            timeSlot: slot,
            cells: {
              for (final day in Weekday.values)
                day: _cell(byKey['${slot.id}|${day.wire}'], view),
            },
          ),
      ],
    );
  }

  static TimetableCell? _cell(ClassTimetableCell? c, ClassTimetableView view) =>
      c == null
      ? null
      : TimetableCell(
          sessionId: c.id,
          coursId: c.coursId!,
          classroomId: c.classroomId,
          classroomLabel: c.teacherLabel ?? '',
          teacherId: c.teacherId ?? '',
          teacherLabel: c.teacherLabel ?? '',
          subjectLabel: c.subjectLabel ?? '',
          room: view.classroom.room,
        );

  /// Chaque cours prend la teinte de son domaine, dans l'ordre du bulletin.
  static Map<String, AcademicsClassVisual> courseVisuals(
    ClassTimetableView view,
  ) {
    final order = view.domainOrder;
    return {
      for (final course in view.programme)
        course.coursId: () {
          final tone = CourseDomainTones.forDomain(course.domainId, order);
          return AcademicsClassVisual(accent: tone.ink, soft: tone.soft);
        }(),
    };
  }

  /// coursId → nom de son domaine, « Sans domaine » à défaut (vue Jour).
  static Map<String, String> domainLabels(
    ClassTimetableView view,
    AppLocalizations l10n,
  ) => {
    for (final course in view.programme)
      course.coursId: course.domainLabel ?? l10n.classTimetableNoDomain,
  };

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}:00';
}

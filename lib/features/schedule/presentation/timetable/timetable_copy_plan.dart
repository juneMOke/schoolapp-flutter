import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/copy_source.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_copy.dart';

/// La copie d'une source vers le brouillon d'une classe : la fonction pure
/// partagée (`TimetableCopy`, tenue par `copy-vectors.json`), rendue en
/// changements de cases — toutes les cases de la grille, pleines ou vides
/// (A6 : la copie ne monte pas comme geste, elle monte en 36 cases).
class TimetableCopyPlan {
  final TimetableCopyResult result;
  final List<CellChange> changes;

  const TimetableCopyPlan(this.result, this.changes);

  static TimetableCopyPlan of(ClassTimetableView target, CopySource source) {
    final slots = {for (final s in target.slots) s.id: s};
    final result = TimetableCopy.compute(
      targetClassroomId: target.classroom.classroomId,
      slots: [
        for (final s in target.slots)
          if (MinuteRange.fromClocks(s.startTime, s.endTime) case final range?)
            GridSlot(slotId: s.id, order: s.order, range: range),
      ],
      sourceCells: [
        // Un cours de la source sans branche connue (sorti de son programme)
        // compte « sans cours équivalent » : une branche qu'aucun cours de la
        // cible ne porte.
        for (final c in source.cells)
          if (c.coursId case final coursId?)
            SourceCell(
              day: c.day,
              slotId: c.slotId,
              coursId: coursId,
              branchId: source.branchByCours[coursId] ?? '?$coursId',
            ),
      ],
      targetCourses: [
        for (final c in target.programme)
          ProgrammeCourse(
            coursId: c.coursId,
            branchId: c.branchId,
            teacherId: c.teacherId,
          ),
      ],
      otherBookings: target.bookings,
    );
    final byCours = {for (final c in target.programme) c.coursId: c};
    return TimetableCopyPlan(result, [
      for (final cell in result.cells)
        if (slots[cell.slotId] case final slot?)
          CellChange(cell.day, slot, byCours[cell.coursId]),
    ]);
  }
}

import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Les conflits professeur du brouillon, calculés sur l'appareil (R4, A11) :
/// contre les versions publiées et les brouillons des autres classes connus
/// de l'appareil, sur les minutes qui se chevauchent.
class DraftConflicts {
  const DraftConflicts._();

  /// Les cases du brouillon en conflit, et la classe qui occupe l'enseignant.
  static Map<String, TeacherBooking> of(ClassTimetableView view) {
    final conflicts = <String, TeacherBooking>{};
    for (final cell in view.draft) {
      if (cell.isEmpty) continue;
      final booking = _first(view, cell.teacherId, cell.day, cell.range);
      if (booking != null) conflicts[cell.id] = booking;
    }
    return conflicts;
  }

  /// Pourquoi [course] ne peut pas aller dans ce créneau, `null` s'il le peut.
  static TeacherBooking? blocking(
    ClassTimetableView view,
    TimetableCourse course,
    Weekday day,
    TimeSlot slot,
  ) {
    final range = MinuteRange.fromClocks(slot.startTime, slot.endTime);
    return range == null ? null : _first(view, course.teacherId, day, range);
  }

  static TeacherBooking? _first(
    ClassTimetableView view,
    String? teacherId,
    Weekday day,
    MinuteRange range,
  ) {
    final found = SlotOverlap.conflictsFor(
      teacherId: teacherId,
      classroomId: view.classroom.classroomId,
      day: day,
      range: range,
      bookings: view.bookings,
    );
    return found.isEmpty ? null : found.first;
  }
}

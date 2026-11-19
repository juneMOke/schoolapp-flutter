import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_conflicts.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';

/// Ce qu'un dépôt produit : les cases à écrire (un seul geste, une seule
/// horloge — un échange reste un geste), ou le conflit qui le refuse.
sealed class DraftDropOutcome {
  const DraftDropOutcome();
}

/// Rien à faire : déposé sur sa propre case.
final class DropIgnored extends DraftDropOutcome {
  const DropIgnored();
}

final class DropAccepted extends DraftDropOutcome {
  final List<CellChange> changes;

  const DropAccepted(this.changes);
}

/// Refusé avant tout enregistrement (I9, A5, A6) : [course] a déjà cours
/// ailleurs ([booking]).
final class DropRefused extends DraftDropOutcome {
  final TimetableCourse course;
  final TeacherBooking booking;

  const DropRefused(this.course, this.booking);
}

/// Le glisser-déposer du brouillon (I9 à I11), sur l'appareil.
class DraftDrop {
  const DraftDrop._();

  static TimetableCourse? _course(ClassTimetableView view, String? coursId) {
    for (final c in view.programme) {
      if (c.coursId == coursId) return c;
    }
    return null;
  }

  static ClassTimetableCell? _at(
    ClassTimetableView view,
    Weekday day,
    TimeSlot slot,
  ) {
    for (final c in view.draft) {
      if (c.day == day && c.slotId == slot.id && !c.isEmpty) return c;
    }
    return null;
  }

  /// Déposer [data] sur le créneau ([day], [slot]) : un cours de la réserve
  /// s'y pose (I9) ; une séance s'y déplace, ou s'échange avec celle qui
  /// l'occupe (I10, A6) — refusé si l'un des deux sens crée un conflit.
  static DraftDropOutcome onSlot(
    ClassTimetableView view,
    TimetableDragData data,
    Weekday day,
    TimeSlot slot,
  ) {
    switch (data) {
      case CourseDragData(:final coursId):
        final course = _course(view, coursId);
        if (course == null) return const DropIgnored();
        if (DraftConflicts.blocking(view, course, day, slot) case final b?) {
          return DropRefused(course, b);
        }
        return DropAccepted([CellChange(day, slot, course)]);
      case SessionDragData(
        cell: final cell,
        day: final fromDay,
        slot: final from,
      ):
        return _move(view, cell.coursId, fromDay, from, day, slot);
    }
  }

  static DraftDropOutcome _move(
    ClassTimetableView view,
    String coursId,
    Weekday fromDay,
    TimeSlot from,
    Weekday day,
    TimeSlot to,
  ) {
    if (fromDay == day && from.id == to.id) return const DropIgnored();
    final moving = _course(view, coursId);
    if (moving == null) return const DropIgnored();
    final other = _course(view, _at(view, day, to)?.coursId);
    if (DraftConflicts.blocking(view, moving, day, to) case final b?) {
      return DropRefused(moving, b);
    }
    if (other != null) {
      if (DraftConflicts.blocking(view, other, fromDay, from) case final b?) {
        return DropRefused(other, b);
      }
    }
    return DropAccepted([
      CellChange(fromDay, from, other),
      CellChange(day, to, moving),
    ]);
  }

  /// Déposer une séance sur la réserve la retire (I11).
  static DraftDropOutcome onReserve(TimetableDragData data) => switch (data) {
    SessionDragData(:final day, :final slot) => DropAccepted([
      CellChange(day, slot, null),
    ]),
    CourseDragData() => const DropIgnored(),
  };
}

import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';

/// La récréation entre deux séances : un trou dans la grille de sonnerie **de
/// l'école** entre la fin de l'une et le début de l'autre.
///
/// Un écart entre deux séances du professeur ne suffit pas : il peut n'être
/// qu'une heure libre, sans pause de l'école.
abstract final class JournalBreaks {
  /// [schoolSlots] : tous les créneaux de l'école, triés par rang.
  static JournalBreak? between(
    List<TimeSlot> schoolSlots, {
    required TimeSlot before,
    required TimeSlot after,
  }) {
    for (var i = 0; i + 1 < schoolSlots.length; i++) {
      final slot = schoolSlots[i];
      final next = schoolSlots[i + 1];
      if (slot.order < before.order || next.order > after.order) continue;
      if (_hhmm(slot.endTime) != _hhmm(next.startTime)) {
        return JournalBreak(start: slot.endTime, end: next.startTime);
      }
    }
    return null;
  }

  /// `08:20:00` et `08:20` désignent la même heure.
  static String _hhmm(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;
}

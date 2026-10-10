import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';

/// Une ligne de la journée d'un professeur telle que le serveur l'assemble
/// pour la direction (`GET /academics/journal`) : séances de l'emploi du
/// temps ∪ séances écrites, triées par créneau.
class JournalReadLine extends Equatable {
  final String coursId;
  final String subjectLabel;
  final String classroomLabel;

  /// `null` : une séance écrite dont le créneau a disparu.
  final TimeSlot? slot;

  /// L'identifiant du créneau, même disparu.
  final String timeSlotId;
  final bool inTimetable;

  /// `null` : pas encore écrite.
  final JournalEntry? entry;

  const JournalReadLine({
    required this.coursId,
    required this.subjectLabel,
    required this.classroomLabel,
    required this.timeSlotId,
    required this.inTimetable,
    this.slot,
    this.entry,
  });

  @override
  List<Object?> get props => [
    coursId,
    subjectLabel,
    classroomLabel,
    slot,
    timeSlotId,
    inTimetable,
    entry,
  ];
}

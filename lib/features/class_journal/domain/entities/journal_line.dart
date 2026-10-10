import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';

/// L'étiquette « Chap. i · séance n » d'une séance rattachée.
class JournalChapterTag extends Equatable {
  /// Rang du chapitre dans le cours, à partir de 1.
  final int number;
  final String title;

  /// Rang de cette séance parmi les séances renseignées du chapitre ; `null`
  /// tant qu'elle n'est pas renseignée.
  final int? seanceNo;

  const JournalChapterTag({
    required this.number,
    required this.title,
    this.seanceNo,
  });

  @override
  List<Object?> get props => [number, title, seanceNo];
}

/// Une pause de la grille de sonnerie de l'école (heures `HH:mm:ss`).
class JournalBreak extends Equatable {
  final String start;
  final String end;

  const JournalBreak({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

/// Une ligne de la feuille du jour : une séance, et ce qui y a été saisi.
class JournalLine extends Equatable {
  final TimeSlot slot;
  final String coursId;

  /// La branche (matière) du cours.
  final String subjectLabel;
  final String classroomLabel;

  /// `null` : séance vierge.
  final JournalEntry? entry;

  /// `false` : une entrée dont la séance n'est plus à l'emploi du temps
  /// actuel — elle reste lisible à sa date.
  final bool scheduled;
  final JournalStatus status;
  final JournalChapterTag? chapter;

  /// La pause de l'école entre la ligne précédente et celle-ci, s'il y en a.
  final JournalBreak? breakBefore;

  const JournalLine({
    required this.slot,
    required this.coursId,
    required this.subjectLabel,
    required this.classroomLabel,
    required this.status,
    this.entry,
    this.scheduled = true,
    this.chapter,
    this.breakBefore,
  });

  JournalSeanceKey keyOn(DateTime date) =>
      JournalSeanceKey(coursId: coursId, date: date, timeSlotId: slot.id);

  bool get isFilled => status == JournalStatus.filled;

  JournalLine withBreakBefore(JournalBreak? pause) => JournalLine(
    slot: slot,
    coursId: coursId,
    subjectLabel: subjectLabel,
    classroomLabel: classroomLabel,
    status: status,
    entry: entry,
    scheduled: scheduled,
    chapter: chapter,
    breakBefore: pause,
  );

  @override
  List<Object?> get props => [
    slot,
    coursId,
    subjectLabel,
    classroomLabel,
    entry,
    scheduled,
    status,
    chapter,
    breakBefore,
  ];
}

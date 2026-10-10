import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
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

  const JournalLine({
    required this.slot,
    required this.coursId,
    required this.subjectLabel,
    required this.classroomLabel,
    required this.status,
    this.entry,
    this.scheduled = true,
    this.chapter,
  });

  bool get isFilled => status == JournalStatus.filled;

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
  ];
}

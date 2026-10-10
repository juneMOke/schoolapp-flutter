import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';

/// Une page du journal : un jour et ses séances, triées par créneau.
class JournalDay extends Equatable {
  /// Le jour civil (minuit, heure locale).
  final DateTime date;
  final List<JournalLine> lines;

  /// Rang du jour parmi les jours de cours de l'année ; `null` quand il ne se
  /// calcule pas (jour sans cours, année sans date de début).
  final int? pageNumber;

  /// Le prochain jour où le professeur a cours ; `null` s'il n'y en a pas.
  final DateTime? nextCourseDay;

  const JournalDay({
    required this.date,
    required this.lines,
    this.pageNumber,
    this.nextCourseDay,
  });

  bool get isEmpty => lines.isEmpty;

  int get filledCount => lines.where((l) => l.isFilled).length;

  bool get isComplete => lines.isNotEmpty && filledCount == lines.length;

  @override
  List<Object?> get props => [date, lines, pageNumber, nextCourseDay];
}

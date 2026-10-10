import 'package:equatable/equatable.dart';

/// Ce qui désigne une séance du journal : un cours, un jour, un créneau.
class JournalSeanceKey extends Equatable {
  final String coursId;

  /// Le jour civil (minuit, heure locale).
  final DateTime date;
  final String timeSlotId;

  const JournalSeanceKey({
    required this.coursId,
    required this.date,
    required this.timeSlotId,
  });

  @override
  List<Object?> get props => [coursId, date, timeSlotId];
}

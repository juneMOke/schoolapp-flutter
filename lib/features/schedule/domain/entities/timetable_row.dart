import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Une ligne de la grille : un [timeSlot] (créneau de sonnerie) et, pour chaque
/// jour, la séance de ce créneau ce jour-là — ou `null` si le créneau est libre.
class TimetableRow extends Equatable {
  final TimeSlot timeSlot;

  /// Case par jour. `null` (ou jour absent) = créneau **libre** ce jour-là :
  /// c'est un état normal de la grille, **pas** une erreur.
  final Map<Weekday, TimetableCell?> cells;

  const TimetableRow({required this.timeSlot, required this.cells});

  /// Séance de ce créneau pour [day], ou `null` si le créneau est libre.
  TimetableCell? cellFor(Weekday day) => cells[day];

  @override
  List<Object?> get props => [timeSlot, cells];
}

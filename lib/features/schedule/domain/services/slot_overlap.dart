import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Une plage horaire d'un jour, en minutes depuis minuit (A11, A12).
class MinuteRange extends Equatable {
  final int startMinute;
  final int endMinute;

  const MinuteRange(this.startMinute, this.endMinute);

  /// `HH:mm` ou `HH:mm:ss` → minutes ; `null` si illisible.
  static int? parseClock(String? raw) {
    final parts = raw?.split(':');
    if (parts == null || parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return hours * 60 + minutes;
  }

  static MinuteRange? fromClocks(String? start, String? end) {
    final s = parseClock(start);
    final e = parseClock(end);
    return s == null || e == null ? null : MinuteRange(s, e);
  }

  @override
  List<Object?> get props => [startMinute, endMinute];
}

/// Une séance qui occupe un enseignant : dans une autre classe, publiée ou en
/// brouillon (EDT-R4, Q4).
class TeacherBooking extends Equatable {
  final String teacherId;
  final Weekday day;
  final MinuteRange range;
  final String classroomId;
  final String classroomLabel;

  const TeacherBooking({
    required this.teacherId,
    required this.day,
    required this.range,
    required this.classroomId,
    required this.classroomLabel,
  });

  @override
  List<Object?> get props => [
    teacherId,
    day,
    range,
    classroomId,
    classroomLabel,
  ];
}

/// « Un professeur, un lieu » jugé sur les **minutes qui se chevauchent**, et
/// non sur le numéro du créneau : deux grilles de cycles différents coexistent
/// (EDT-R1, R4, A25).
///
/// Deux plages jointives (fin 08:20, début 08:20) ne sont pas en conflit (A11).
/// Les vecteurs `schedule/overlap-vectors.json` (lot V0) tiennent la règle
/// identique à `SlotOverlap` côté serveur.
class SlotOverlap {
  const SlotOverlap._();

  static bool overlaps(MinuteRange a, MinuteRange b) =>
      a.startMinute < b.endMinute && b.startMinute < a.endMinute;

  /// Les réservations qui empêchent [teacherId] d'être placé dans
  /// [classroomId] le [day] sur [range]. Un cours sans enseignant n'a jamais
  /// de conflit (R3) ; la classe elle-même n'est jamais comparée à elle-même.
  static List<TeacherBooking> conflictsFor({
    required String? teacherId,
    required String classroomId,
    required Weekday day,
    required MinuteRange range,
    required Iterable<TeacherBooking> bookings,
  }) {
    if (teacherId == null || teacherId.isEmpty) return const [];
    return [
      for (final booking in bookings)
        if (booking.teacherId == teacherId &&
            booking.classroomId != classroomId &&
            booking.day == day &&
            overlaps(booking.range, range))
          booking,
    ];
  }
}

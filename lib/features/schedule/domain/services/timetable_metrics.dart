import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Heures placées / prévues d'un cours (EDT-R5 : une séance vaut une heure).
class CourseVolume extends Equatable {
  final String coursId;
  final int placed;

  /// `null` : volume inconnu (B2, `weeklyHours` absent) — rien ne s'affiche.
  final int? planned;

  const CourseVolume({
    required this.coursId,
    required this.placed,
    required this.planned,
  });

  /// Reste à placer (négatif : excès).
  int? get remaining => planned == null ? null : planned! - placed;

  bool get isComplete => remaining == 0;

  bool get isOver => (remaining ?? 0) < 0;

  @override
  List<Object?> get props => [coursId, placed, planned];
}

/// Comptes d'un emploi du temps, calculés à l'écran (EDT-D6, D7).
class PlacedHours {
  const PlacedHours._();

  /// Un volume par cours du programme, dans l'ordre de [plannedByCours] ; un
  /// cours prévu à 0 h n'est pas proposé (R5).
  static List<CourseVolume> volumes({
    required Map<String, int?> plannedByCours,
    required Iterable<String?> placedCoursIds,
  }) {
    final counts = <String, int>{};
    for (final id in placedCoursIds) {
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return [
      for (final entry in plannedByCours.entries)
        if (entry.value != 0)
          CourseVolume(
            coursId: entry.key,
            placed: counts[entry.key] ?? 0,
            planned: entry.value,
          ),
    ];
  }

  /// Total placé / prévu ; prévu `null` dès qu'un volume est inconnu.
  static (int placed, int? planned) totals(List<CourseVolume> volumes) {
    var placed = 0;
    int? planned = 0;
    for (final volume in volumes) {
      placed += volume.placed;
      planned = (planned == null || volume.planned == null)
          ? null
          : planned + volume.planned!;
    }
    return (placed, planned);
  }
}

/// Une séance de la journée, pour « En cours » et « Ensuite » (EDT-R11).
class DaySession extends Equatable {
  final String id;
  final MinuteRange range;

  const DaySession({required this.id, required this.range});

  @override
  List<Object?> get props => [id, range];
}

class CurrentSessionState extends Equatable {
  final DaySession? current;
  final DaySession? next;

  const CurrentSessionState({this.current, this.next});

  /// Plus rien aujourd'hui (ni en cours, ni à venir).
  bool get isOver => current == null && next == null;

  @override
  List<Object?> get props => [current, next];
}

/// « En cours » et « Ensuite », à l'heure **de l'école** (EDT-R11).
class CurrentSession {
  const CurrentSession._();

  static Weekday? weekdayOf(DateTime schoolWallClock) =>
      switch (schoolWallClock.weekday) {
        DateTime.monday => Weekday.mon,
        DateTime.tuesday => Weekday.tue,
        DateTime.wednesday => Weekday.wed,
        DateTime.thursday => Weekday.thu,
        DateTime.friday => Weekday.fri,
        DateTime.saturday => Weekday.sat,
        _ => null,
      };

  static CurrentSessionState at({
    required int minuteOfDay,
    required List<DaySession> sessions,
  }) {
    final sorted = [...sessions]
      ..sort((a, b) => a.range.startMinute.compareTo(b.range.startMinute));
    DaySession? current;
    DaySession? next;
    for (final session in sorted) {
      final r = session.range;
      if (r.startMinute <= minuteOfDay && minuteOfDay < r.endMinute) {
        current = session;
      } else if (r.startMinute > minuteOfDay && next == null) {
        next = session;
      }
    }
    return CurrentSessionState(current: current, next: next);
  }
}

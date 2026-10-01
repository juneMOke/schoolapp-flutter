import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Une case du calendrier d'une fiche mensuelle (lundi → vendredi).
class PresenceCalendarDay extends Equatable {
  /// `YYYY-MM-DD`.
  final String day;

  /// Jour à venir (estompé), ou hors de l'année scolaire.
  final bool upcoming;
  final PresenceStatus status;

  const PresenceCalendarDay({
    required this.day,
    required this.upcoming,
    this.status = PresenceStatus.none,
  });

  @override
  List<Object?> get props => [day, upcoming, status];
}

/// Un retard ou une absence du mois, tel que la fiche le liste.
class PresenceIncident<R extends Object> extends Equatable {
  /// `YYYY-MM-DD`.
  final String day;
  final PresenceStatus status;
  final ClockTime? arrival;
  final int lateMinutes;

  /// Le motif ; `null` = non justifié.
  final R? reason;

  const PresenceIncident({
    required this.day,
    required this.status,
    this.arrival,
    this.lateMinutes = 0,
    this.reason,
  });

  @override
  List<Object?> get props => [day, status, arrival, lateMinutes, reason];
}

/// Les jours d'un mois en semaines complètes du lundi au vendredi : `null`
/// pour une case avant le 1er. [upcoming] dit d'un jour de semaine s'il est
/// à venir ou hors de l'année scolaire ; [statusOf] donne son statut.
List<PresenceCalendarDay?> presenceCalendar({
  required List<String> weekdays,
  required int firstWeekday,
  required bool Function(String day) upcoming,
  required PresenceStatus Function(String day) statusOf,
}) => [
  for (var i = 0; i < firstWeekday - 1; i++) null,
  for (final day in weekdays)
    PresenceCalendarDay(
      day: day,
      upcoming: upcoming(day),
      status: upcoming(day) ? PresenceStatus.none : statusOf(day),
    ),
];

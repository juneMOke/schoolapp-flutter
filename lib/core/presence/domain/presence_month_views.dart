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

  /// Ce que la case écrit sous le jour à la place de l'icône (« 07:52 »,
  /// « +12 min », le motif) ; `null` : l'icône du statut.
  final String? detail;

  const PresenceCalendarDay({
    required this.day,
    required this.upcoming,
    this.status = PresenceStatus.none,
    this.detail,
  });

  @override
  List<Object?> get props => [day, upcoming, status, detail];
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
/// à venir ou hors de l'année scolaire (estompé) ; [statusOf] donne son
/// statut, qu'il soit à venir ou non (une ligne reçue hors des bornes garde
/// sa couleur). [detailOf], facultatif, écrit le détail d'un jour dans sa
/// case.
List<PresenceCalendarDay?> presenceCalendar({
  required List<String> weekdays,
  required int firstWeekday,
  required bool Function(String day) upcoming,
  required PresenceStatus Function(String day) statusOf,
  String? Function(String day)? detailOf,
}) => [
  for (var i = 0; i < firstWeekday - 1; i++) null,
  for (final day in weekdays)
    PresenceCalendarDay(
      day: day,
      upcoming: upcoming(day),
      status: statusOf(day),
      detail: detailOf?.call(day),
    ),
];

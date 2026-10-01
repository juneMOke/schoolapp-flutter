import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Ce qu'on pointe pour une personne un jour donné, sans dire qui ni où :
/// statut, heures, retard et justification. Agent et élève l'emballent dans
/// leur propre ligne ; les règles de cohérence ([PresenceMarkEditor]) sont
/// communes.
class PresenceMark<R extends Object> extends Equatable {
  final PresenceStatus status;
  final ClockTime? arrival;

  /// Heure de départ — le Pointage du personnel seulement.
  final ClockTime? departure;

  /// Minutes comptées depuis le début des cours ; 0 hors retard.
  final int lateMinutes;
  final PresenceJustification<R>? justification;

  const PresenceMark({
    required this.status,
    this.arrival,
    this.departure,
    this.lateMinutes = 0,
    this.justification,
  });

  /// « À pointer », tout à vide.
  const PresenceMark.none()
    : status = PresenceStatus.none,
      arrival = null,
      departure = null,
      lateMinutes = 0,
      justification = null;

  bool get isJustified => justification != null;

  /// Un retard ou une absence sans justification.
  bool get needsJustification => status.isIncident && !isJustified;

  @override
  List<Object?> get props => [
    status,
    arrival,
    departure,
    lateMinutes,
    justification,
  ];
}

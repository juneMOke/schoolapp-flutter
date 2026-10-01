import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Les modifications d'une [PresenceMark], chacune rendant une marque
/// **cohérente** au sens des deux serveurs (Pointage et appel) :
/// - à pointer : tout à vide ;
/// - présent : arrivée, retard 0, pas de justification ;
/// - en retard : arrivée, retard > 0 ;
/// - absent : ni arrivée, ni départ.
///
/// Calcul pur : l'écriture et la mise en file sont l'affaire des modules.
class PresenceMarkEditor {
  final PresenceRules rules;

  const PresenceMarkEditor(this.rules);

  /// Pose [status] avec l'heure proposée ; garde le départ quand le statut
  /// garde une arrivée.
  PresenceMark<R> mark<R extends Object>(
    PresenceMark<R> mark,
    PresenceStatus status,
    ClockTime now,
  ) {
    if (status == PresenceStatus.none) return clear(mark);
    if (status == PresenceStatus.absent) {
      return PresenceMark<R>(
        status: PresenceStatus.absent,
        justification: mark.justification,
      );
    }
    final arrival = rules.suggestedArrival(status, now)!;
    final late = status == PresenceStatus.late;
    return PresenceMark<R>(
      status: status,
      arrival: arrival,
      departure: _departureAfter(mark.departure, arrival),
      lateMinutes: late ? arrival.minutesSince(rules.schedule.start) : 0,
      justification: late ? mark.justification : null,
    );
  }

  /// Saisit l'arrivée : le statut suit le classement, et repasser à l'heure
  /// retire la justification devenue sans objet.
  PresenceMark<R> setArrival<R extends Object>(
    PresenceMark<R> mark,
    ClockTime arrival,
  ) {
    final result = rules.classify(arrival);
    final late = result.status == PresenceStatus.late;
    return PresenceMark<R>(
      status: result.status,
      arrival: arrival,
      departure: _departureAfter(mark.departure, arrival),
      lateMinutes: result.lateMinutes,
      justification: late ? mark.justification : null,
    );
  }

  /// Saisit ou efface le départ. Sans arrivée (absent, à pointer), rien ne
  /// change : un départ n'y a pas de sens. Un départ antérieur à l'arrivée
  /// est une saisie fausse : rien ne change non plus, plutôt que d'effacer
  /// en silence le départ existant.
  PresenceMark<R> setDeparture<R extends Object>(
    PresenceMark<R> mark,
    ClockTime? departure,
  ) {
    final arrival = mark.arrival;
    if (!mark.status.hasArrival || arrival == null) return mark;
    if (departure != null && departure.compareTo(arrival) < 0) return mark;
    return PresenceMark<R>(
      status: mark.status,
      arrival: arrival,
      departure: departure,
      lateMinutes: mark.lateMinutes,
      justification: mark.justification,
    );
  }

  /// Pose ou retire une justification — seulement sur un retard ou une
  /// absence.
  PresenceMark<R> justify<R extends Object>(
    PresenceMark<R> mark,
    PresenceJustification<R>? justification,
  ) {
    if (!mark.status.isIncident) return mark;
    return PresenceMark<R>(
      status: mark.status,
      arrival: mark.arrival,
      departure: mark.departure,
      lateMinutes: mark.lateMinutes,
      justification: justification,
    );
  }

  /// Remet « à pointer » : tout à vide, justification comprise.
  PresenceMark<R> clear<R extends Object>(PresenceMark<R> mark) =>
      PresenceMark<R>.none();

  /// Un départ antérieur à l'arrivée n'est pas gardé.
  static ClockTime? _departureAfter(ClockTime? departure, ClockTime arrival) =>
      departure != null && departure.compareTo(arrival) >= 0 ? departure : null;
}

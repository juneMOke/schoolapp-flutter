import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Le classement d'une arrivée, avec l'horaire que la tablette a tiré.
///
/// La tablette est **seule** à classer : le serveur stocke le statut et les
/// minutes tels quels. Un pointage fait sous 07:30 / 10 min garde son
/// classement même si le réglage change avant la synchronisation.
class PresenceRules {
  final PresenceSchedule schedule;

  const PresenceRules(this.schedule);

  /// Délai ajouté à la fin de la tolérance pour proposer une heure de retard
  /// quand l'heure courante est encore « à l'heure ».
  static const int suggestedLateDelay = 15;

  /// Après début + tolérance : en retard, **compté depuis le début des cours**
  /// (pas depuis la fin de la tolérance). Sinon présent.
  ArrivalClass classify(ClockTime arrival) {
    if (arrival.isAfter(schedule.lastOnTime)) {
      return ArrivalClass(
        PresenceStatus.late,
        arrival.minutesSince(schedule.start),
      );
    }
    return const ArrivalClass(PresenceStatus.present, 0);
  }

  /// L'heure proposée quand on pose [status] sans saisir d'heure.
  ///
  /// Présent : l'heure courante si elle est dans la tolérance, sinon le début.
  /// En retard : l'heure courante si elle est au-delà, sinon début +
  /// tolérance + [suggestedLateDelay]. `null` pour un statut sans arrivée.
  ClockTime? suggestedArrival(PresenceStatus status, ClockTime now) {
    final late = now.isAfter(schedule.lastOnTime);
    return switch (status) {
      PresenceStatus.present => late ? schedule.start : now,
      PresenceStatus.late =>
        late ? now : schedule.lastOnTime.plus(suggestedLateDelay),
      PresenceStatus.absent || PresenceStatus.none => null,
    };
  }

  /// Le cycle d'un toucher sur une carte : présent › en retard › absent ›
  /// présent. « À pointer » ne s'atteint que par l'effacement explicite.
  static PresenceStatus nextInCycle(PresenceStatus current) =>
      switch (current) {
        PresenceStatus.none || PresenceStatus.absent => PresenceStatus.present,
        PresenceStatus.present => PresenceStatus.late,
        PresenceStatus.late => PresenceStatus.absent,
      };
}

/// Le résultat d'un classement : le statut et les minutes de retard.
class ArrivalClass {
  final PresenceStatus status;
  final int lateMinutes;

  const ArrivalClass(this.status, this.lateMinutes);
}

import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';

/// Le classement d'une arrivée, avec les réglages que la tablette a tirés.
///
/// La tablette est **seule** à classer : le serveur stocke le statut et les
/// minutes tels quels. Un pointage fait sous 07:30 / 10 min garde son
/// classement même si le réglage change avant la synchronisation.
class StaffAttendanceRules {
  final StaffAttendanceSettings settings;

  const StaffAttendanceRules(this.settings);

  /// Délai ajouté à la fin de la tolérance pour proposer une heure de retard
  /// quand l'heure courante est encore « à l'heure ».
  static const int suggestedLateDelay = 15;

  /// Après début + tolérance : en retard, **compté depuis le début des cours**
  /// (pas depuis la fin de la tolérance). Sinon présent.
  StaffArrivalClass classify(StaffClockTime arrival) {
    if (arrival.isAfter(settings.lastOnTime)) {
      return StaffArrivalClass(
        StaffAttendanceStatus.late,
        arrival.minutesSince(settings.start),
      );
    }
    return const StaffArrivalClass(StaffAttendanceStatus.present, 0);
  }

  /// L'heure proposée quand on pose [status] sans saisir d'heure.
  ///
  /// Présent : l'heure courante si elle est dans la tolérance, sinon le début.
  /// En retard : l'heure courante si elle est au-delà, sinon début +
  /// tolérance + [suggestedLateDelay]. `null` pour un statut sans arrivée.
  StaffClockTime? suggestedArrival(
    StaffAttendanceStatus status,
    StaffClockTime now,
  ) {
    final late = now.isAfter(settings.lastOnTime);
    return switch (status) {
      StaffAttendanceStatus.present => late ? settings.start : now,
      StaffAttendanceStatus.late =>
        late ? now : settings.lastOnTime.plus(suggestedLateDelay),
      StaffAttendanceStatus.absent || StaffAttendanceStatus.none => null,
    };
  }

  /// Le cycle d'un toucher sur une carte : présent › en retard › absent ›
  /// présent. « À pointer » ne s'atteint que par l'effacement explicite.
  static StaffAttendanceStatus nextInCycle(StaffAttendanceStatus current) =>
      switch (current) {
        StaffAttendanceStatus.none ||
        StaffAttendanceStatus.absent => StaffAttendanceStatus.present,
        StaffAttendanceStatus.present => StaffAttendanceStatus.late,
        StaffAttendanceStatus.late => StaffAttendanceStatus.absent,
      };
}

/// Le résultat d'un classement : le statut et les minutes de retard.
class StaffArrivalClass {
  final StaffAttendanceStatus status;
  final int lateMinutes;

  const StaffArrivalClass(this.status, this.lateMinutes);
}

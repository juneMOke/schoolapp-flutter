import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// La forme sur le fil (et en base) du statut d'une ligne d'appel, contrat
/// `/sync/attendance` v2 : `ABSENT` ou `LATE`. Une présence n'a pas de ligne.
///
/// ⚠️ Un statut **manquant** dans un message se lit côté serveur « client
/// ancien » : il garde le statut en base. La tablette v2 l'envoie donc
/// TOUJOURS — sans quoi elle ne pourrait plus faire d'un retard une absence.
abstract final class AttendanceLineWire {
  static const String absent = 'ABSENT';
  static const String late = 'LATE';

  /// Le statut d'une ligne lue : `status` quand il est posé, sinon d'après
  /// `present` (ligne d'avant la v2). Inconnu ⇒ d'après `present` aussi.
  static PresenceStatus read(String? status, {required bool present}) =>
      switch (status) {
        late => PresenceStatus.late,
        absent => PresenceStatus.absent,
        _ => present ? PresenceStatus.present : PresenceStatus.absent,
      };

  /// Une heure reçue, ramenée à `HH:mm` (le serveur peut écrire des
  /// secondes) : sans cela, une ligne inchangée se lirait « modifiée » et
  /// regagnerait à tort un arbitrage LWW au prochain renvoi.
  static String? arrival(String? value) =>
      ClockTime.tryParse(value)?.wire ?? value;

  /// `ABSENT` ou `LATE` ; une présence ou « à pointer » n'a pas de ligne.
  static String write(PresenceStatus status) => switch (status) {
    PresenceStatus.late => late,
    PresenceStatus.absent => absent,
    PresenceStatus.present || PresenceStatus.none => throw ArgumentError(
      'Seuls un retard ou une absence portent une ligne d\'appel.',
    ),
  };
}

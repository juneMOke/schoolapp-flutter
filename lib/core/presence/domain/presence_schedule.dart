import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';

/// L'horaire d'une école pour le pointage et l'appel : l'heure de début des
/// cours et la tolérance avant retard.
///
/// Il s'applique **aux pointages à venir** : la tablette classe au moment du
/// pointage, et un horaire changé ensuite ne reclasse rien.
class PresenceSchedule extends Equatable {
  final ClockTime start;

  /// Une des [tolerances].
  final int toleranceMinutes;

  const PresenceSchedule({required this.start, required this.toleranceMinutes});

  /// Les tolérances proposées, en minutes.
  static const List<int> tolerances = [0, 5, 10, 15, 20];

  /// L'école qui n'a rien posé : 07:30, 10 minutes.
  static final PresenceSchedule defaults = PresenceSchedule(
    start: ClockTime.fromMinutes(7 * 60 + 30),
    toleranceMinutes: 10,
  );

  /// L'heure de début la plus tardive qu'on puisse régler : au-delà, la fin
  /// de la tolérance et une arrivée « en retard » ne tiendraient plus dans la
  /// journée, et le serveur refuserait un retard de 0 minute.
  static final ClockTime latestStart = ClockTime.fromMinutes(18 * 60);

  /// La dernière heure encore « à l'heure ».
  ClockTime get lastOnTime => start.plus(toleranceMinutes);

  @override
  List<Object?> get props => [start, toleranceMinutes];
}

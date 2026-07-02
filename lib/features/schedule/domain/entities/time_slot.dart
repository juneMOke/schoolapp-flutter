import 'package:equatable/equatable.dart';

/// Créneau de sonnerie : une ligne de la grille d'emploi du temps.
///
/// [startTime]/[endTime] sont des **heures pures** au format `HH:mm:ss`
/// (ex. `08:00:00`), conservées en `String` : ce ne sont pas des instants
/// datés — aucune ambiguïté de fuseau, réplicable offline tel quel. La
/// conversion en `TimeOfDay` pour l'affichage relève de la couche UI.
class TimeSlot extends Equatable {
  final String id;
  final int order;
  final String startTime;
  final String endTime;

  /// Libellé optionnel du créneau (ex. « Récréation »).
  final String? label;

  const TimeSlot({
    required this.id,
    required this.order,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  @override
  List<Object?> get props => [id, order, startTime, endTime, label];
}

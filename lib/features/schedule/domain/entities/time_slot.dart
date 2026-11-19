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

  /// La récréation de la grille (EDT-R1) : une bande, jamais un créneau où
  /// poser une séance. Posée par la composition locale, pas par le serveur.
  final bool isBreak;

  const TimeSlot({
    required this.id,
    required this.order,
    required this.startTime,
    required this.endTime,
    this.label,
    this.isBreak = false,
  });

  /// L'ordre d'affichage : l'heure de début, puis l'ordre dans la grille.
  /// Deux grilles de cycles coexistent (EDT-R1) : l'ordre d'un créneau dans sa
  /// grille ne dit plus rien de l'heure.
  static int compareByTime(TimeSlot a, TimeSlot b) {
    final byStart = _minutes(a.startTime).compareTo(_minutes(b.startTime));
    if (byStart != 0) return byStart;
    final byEnd = _minutes(a.endTime).compareTo(_minutes(b.endTime));
    return byEnd != 0 ? byEnd : a.order.compareTo(b.order);
  }

  static int _minutes(String clock) {
    final parts = clock.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  @override
  List<Object?> get props => [id, order, startTime, endTime, label, isBreak];
}

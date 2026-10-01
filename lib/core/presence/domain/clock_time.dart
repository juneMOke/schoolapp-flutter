import 'package:equatable/equatable.dart';

/// Une heure de la journée, à la minute, sans fuseau ni date : l'heure
/// d'arrivée ou de départ d'un agent, ou le début des cours.
///
/// Sur le fil : `HH:mm`, jamais de secondes (le serveur les refuse).
class ClockTime extends Equatable implements Comparable<ClockTime> {
  /// Minutes depuis minuit, de 0 à 1439.
  final int minutes;

  const ClockTime._(this.minutes);

  /// Borne [minutes] dans la journée plutôt que de passer minuit.
  factory ClockTime.fromMinutes(int minutes) =>
      ClockTime._(minutes.clamp(0, _lastMinute));

  factory ClockTime.of(DateTime moment) {
    final local = moment.toLocal();
    return ClockTime._(local.hour * 60 + local.minute);
  }

  /// `HH:mm` (ou `H:mm`), sinon `null`. Des secondes éventuelles (`08:00:00`)
  /// sont ignorées plutôt que de rendre la valeur illisible.
  static ClockTime? tryParse(String? value) {
    final match = _pattern.firstMatch(value?.trim() ?? '');
    if (match == null) return null;
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    if (hours > 23 || minutes > 59) return null;
    return ClockTime._(hours * 60 + minutes);
  }

  static const int _lastMinute = 24 * 60 - 1;
  static final RegExp _pattern = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');

  ClockTime plus(int delta) => ClockTime.fromMinutes(minutes + delta);

  /// Minutes écoulées depuis [earlier] (négatif s'il est plus tard).
  int minutesSince(ClockTime earlier) => minutes - earlier.minutes;

  bool isAfter(ClockTime other) => minutes > other.minutes;

  /// `HH:mm`, la forme du fil et de l'affichage.
  String get wire {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(minutes ~/ 60)}:${two(minutes % 60)}';
  }

  @override
  int compareTo(ClockTime other) => minutes.compareTo(other.minutes);

  @override
  String toString() => wire;

  @override
  List<Object?> get props => [minutes];
}

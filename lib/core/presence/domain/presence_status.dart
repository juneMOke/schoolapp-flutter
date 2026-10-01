/// Le statut d'une personne pour un jour de classe — agent pointé ou élève à
/// l'appel. Chaque module tient sa forme sur le fil ; la valeur est commune.
///
/// [none] (« à pointer ») n'est pas une absence : c'est l'état d'avant le
/// pointage, ou celui d'un statut effacé.
enum PresenceStatus {
  none,
  present,
  late,
  absent;

  /// Le statut porte-t-il une heure d'arrivée ?
  bool get hasArrival => this == present || this == late;

  /// Le statut admet-il une justification ?
  bool get isIncident => this == late || this == absent;

  /// Pointé : tout sauf « à pointer ».
  bool get isMarked => this != none;
}

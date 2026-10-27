/// Les jours d'un registre touchés par un geste depuis l'ouverture de
/// l'écran — la clé dit ce qu'est un « jour » : une date au Pointage, une
/// classe et une date à l'appel. Seuls eux méritent le rappel en partant,
/// jamais un jour simplement consulté.
class PresenceEditedDays {
  final Set<String> _keys = {};

  void mark(String key) => _keys.add(key);

  bool contains(String key) => _keys.contains(key);
}

/// L'horloge cliente [candidate] (ISO-8601) est-elle strictement plus récente
/// que [current], celle d'une ligne locale ?
///
/// Sans horloge lisible, [candidate] ne gagne jamais ; face à une ligne sans
/// horloge, il gagne toujours. C'est la règle des descentes LWW : une version
/// serveur ne remplace une écriture locale en attente que si elle est plus
/// récente qu'elle.
bool isNewerClock(String? candidate, Object? current) {
  final c = candidate == null ? null : DateTime.tryParse(candidate);
  final l = current is String ? DateTime.tryParse(current) : null;
  if (c == null) return false;
  return l == null || c.isAfter(l);
}

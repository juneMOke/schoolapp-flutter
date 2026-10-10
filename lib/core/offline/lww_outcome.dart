/// Le verdict LWW qu'un accusé d'envoi porte dans `lwwOutcome`.
///
/// - [applied] : la version envoyée a été écrite ;
/// - [superseded] : le serveur détenait une version au moins aussi récente —
///   rien n'a été écrit, et l'accusé rend celle qu'il a retenue.
enum LwwOutcome {
  applied,
  superseded;

  /// `null` sur une valeur absente ou inconnue : l'appelant décide du repli.
  static LwwOutcome? fromWire(Object? raw) => switch (raw) {
    'APPLIED' => applied,
    'SUPERSEDED' => superseded,
    _ => null,
  };
}

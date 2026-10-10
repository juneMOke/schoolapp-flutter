/// Bascules d'une sélection d'identifiants, sans état : les cubits de
/// sélection (contrôle des frais, désactivation) les partagent.
abstract final class SelectionSets {
  /// [selected] avec [id] ajouté, ou retiré s'il y était.
  static Set<String> toggled(Set<String> selected, String id) {
    final next = Set<String>.from(selected);
    if (!next.remove(id)) next.add(id);
    return next;
  }

  /// [selected] avec toute la page [pageIds] cochée, ou décochée si elle
  /// l'était déjà en entier. Le geste ne porte jamais au-delà de la page.
  static Set<String> pageToggled(
    Set<String> selected,
    Iterable<String> pageIds,
  ) {
    final ids = pageIds.toSet();
    if (ids.isEmpty) return selected;
    final next = Set<String>.from(selected);
    if (ids.every(next.contains)) {
      next.removeAll(ids);
    } else {
      next.addAll(ids);
    }
    return next;
  }
}

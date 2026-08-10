/// Holder mémoire de l'**ensemble effectif des permissions** de la session
/// courante (ADR-014 §4), pendant de `CurrentUserContext` pour l'uid.
///
/// Alimenté par la couche auth — login online/offline, refresh, restauration au
/// démarrage — et vidé au wipe/logout. Il existe pour les consommateurs qui
/// vivent **hors de l'arbre de widgets** et ne peuvent donc pas lire
/// `AuthState` : la boucle de synchronisation en premier lieu, qui doit sauter
/// les ressources que le compte n'a pas le droit de lire plutôt que de
/// collectionner des 403.
///
/// **Trois états, pas deux.** `null` = ensemble inconnu (aucune session
/// résolue, ou amorçage pas encore passé par la couche auth) ; liste vide =
/// aucun droit ; liste peuplée = droits connus. La distinction porte : sur
/// `null`, un consommateur ne doit **pas** filtrer — il retombe sur le
/// comportement d'avant ADR-014, où l'on tente l'appel et où le serveur
/// tranche. Filtrer sur un ensemble inconnu couperait toute la synchronisation
/// au moindre trou d'alimentation, alors que ne pas filtrer ne fait, au pire,
/// qu'un appel refusé — le client n'est jamais la frontière de sécurité.
class CurrentPermissions {
  List<String>? _permissions;

  /// Ensemble courant en valeurs sur le fil, ou `null` si inconnu.
  List<String>? get permissions => _permissions;

  /// Pose l'ensemble courant. Une liste vide est conservée telle quelle : elle
  /// dit « aucun droit », ce qui n'est pas « je ne sais pas ».
  void set(List<String> permissions) =>
      _permissions = List<String>.unmodifiable(permissions);

  /// Repasse à l'état inconnu (logout, wipe de session).
  void clear() => _permissions = null;
}

import 'package:school_app_flutter/core/auth/permission_policy.dart';

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
  final List<void Function()> _listeners = [];

  /// Ensemble courant en valeurs sur le fil, ou `null` si inconnu.
  List<String>? get permissions => _permissions;

  /// Pose l'ensemble courant. Une liste vide est conservée telle quelle : elle
  /// dit « aucun droit », ce qui n'est pas « je ne sais pas ». `null` repose
  /// l'état inconnu — utile quand la copie durable du compte n'a jamais été
  /// renseignée (session d'avant la migration v24).
  ///
  /// **Notifie si et seulement si l'ensemble a réellement changé** — voir
  /// [addChangeListener], qui explique pourquoi cette comparaison vit ici.
  void set(List<String>? permissions) {
    final next = permissions == null
        ? null
        : List<String>.unmodifiable(permissions);
    final changed = !_sameSet(_permissions, next);
    _permissions = next;
    if (changed) _notify();
  }

  /// Repasse à l'état inconnu (logout, wipe de session).
  ///
  /// **Notifie TOUJOURS**, contrairement à [set] — et la nuance a coûté un
  /// défaut. Ce n'est pas une écriture d'état, c'est un **événement de fin de
  /// session** : ce qu'il annonce n'est pas « l'ensemble a changé » mais « il
  /// n'y a plus de compte ». Passé par la comparaison, il resterait muet sur un
  /// backend qui n'émet pas encore ce champ — l'ensemble y est déjà `null` au
  /// moment du wipe, donc rien ne changerait, donc rien ne partirait. Le plan de
  /// synchronisation du compte qui s'en va survivrait alors au compte suivant,
  /// et sous F5 il ne déciderait plus d'un affichage mais de ce que ce compte
  /// **tire**.
  void clear() {
    _permissions = null;
    _notify();
  }

  /// S'abonne aux changements **réels** de l'ensemble effectif (ADR-015 F9).
  ///
  /// ## Pourquoi la comparaison vit ici et pas chez l'écrivain
  ///
  /// Le contrat annonce que le plan de synchronisation est relu « chaque fois
  /// qu'un refresh livre un ensemble de permissions différent de celui en
  /// mémoire ». La tentation est de coder cela dans `applyRefresh`. Ce serait
  /// couvrir **un** des six chemins qui alimentent ce holder : login en ligne,
  /// login hors ligne, restauration au démarrage, refresh, tick de fraîcheur,
  /// wipe. Les cinq autres changeraient l'ensemble sans que personne ne le
  /// sache — dont la **bascule de compte** sur tablette partagée, qui est le
  /// cas où se tromper coûte le plus cher.
  ///
  /// La comparaison appartient donc au holder : il est le seul point que tous
  /// les écrivains traversent.
  ///
  /// ## Ensembles, jamais listes
  ///
  /// Rien ne fige l'ordre d'émission du serveur. Comparer en liste ferait
  /// signaler un changement à chaque permutation, donc relire le plan à chaque
  /// refresh — et sous F5 un plan perpétuellement « à relire » restreint le
  /// pull au lieu de simplement être en retard. L'asymétrie tranche : un faux
  /// positif coûte un GET idempotent, un faux négatif laisse un droit élargi
  /// sans effet jusqu'au prochain login.
  ///
  /// ⚠️ `null` n'est **pas** « différent de tout » : un backend qui n'émet pas
  /// encore ce champ laisse l'ensemble à `null` refresh après refresh, et le
  /// traiter comme un changement ferait relire le plan en boucle. `null` n'est
  /// un changement que face à un ensemble connu, et réciproquement.
  void Function() addChangeListener(void Function() listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notify() {
    // Copie défensive : un abonné qui se désabonne depuis son propre rappel
    // modifierait la liste en cours d'itération.
    for (final listener in List<void Function()>.from(_listeners)) {
      try {
        listener();
      } catch (_) {
        // Un abonné qui lève ne doit pas empêcher les autres d'être prévenus,
        // ni faire échouer l'écriture des permissions — qui, elle, a déjà eu
        // lieu.
      }
    }
  }

  /// La comparaison vit dans `permission_policy.dart` : elle était recopiée
  /// ici et dans `PermissionGate`, et les deux copies portaient la même
  /// erreur.
  static bool _sameSet(List<String>? a, List<String>? b) =>
      samePermissionSet(a, b);
}

/// Holder mémoire de l'**uid de l'utilisateur courant** (ADR-010 D-05).
///
/// Alimenté par la couche auth (login online/offline, check au démarrage) et
/// vidé au wipe/logout. Lu **au moment de l'écriture locale** par les chemins
/// offline pour estampiller `authorId` sur chaque payload `/sync` : l'auteur est
/// figé à la **saisie** (D-06), pas au moment de la synchro — même si un autre
/// utilisateur se connecte ensuite sur la tablette, l'écriture garde son auteur.
///
/// Le serveur (`SyncAttributionGuard`, A3) **rejette en 403** tout item d'outbox
/// dont `authorId ≠ uid` du JWT présenté : ce contexte est donc la source de
/// vérité front de l'attribution, mais **jamais** la frontière de sécurité
/// (c'est le serveur qui impose).
class CurrentUserContext {
  String? _uid;

  /// Uid courant, ou `null` si aucune session active.
  String? get uid => _uid;

  /// Pose l'uid courant. Une valeur vide est traitée comme absente (uid inconnu
  /// = backend hérité sans claim `uid` → pas d'estampillage possible).
  void set(String? uid) {
    _uid = (uid != null && uid.isNotEmpty) ? uid : null;
  }

  void clear() {
    _uid = null;
  }
}

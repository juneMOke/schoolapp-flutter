/// Holder mémoire de l'**uid** et du **schoolId** de l'utilisateur courant
/// (ADR-010 D-05).
///
/// Alimenté par la couche auth (login online/offline, check au démarrage) et
/// vidé au wipe/logout. `uid` est lu **au moment de l'écriture locale** par les
/// chemins offline pour estampiller `authorId` sur chaque payload `/sync` :
/// l'auteur est figé à la **saisie** (D-06), pas au moment de la synchro — même
/// si un autre utilisateur se connecte ensuite sur la tablette, l'écriture garde
/// son auteur. `schoolId` est lu par les repositories de pull référentiel pour
/// scoper les données à l'école courante (multi-école sur un même device).
///
/// Le serveur (`SyncAttributionGuard`, A3) **rejette en 403** tout item d'outbox
/// dont `authorId ≠ uid` du JWT présenté : ce contexte est donc la source de
/// vérité front de l'attribution, mais **jamais** la frontière de sécurité
/// (c'est le serveur qui impose).
class CurrentUserContext {
  String? _uid;
  String? _schoolId;

  /// Uid courant, ou `null` si aucune session active.
  String? get uid => _uid;

  /// SchoolId courant, ou `null` si aucune session active.
  String? get schoolId => _schoolId;

  /// Pose l'uid et le schoolId courants. Une valeur vide est traitée comme
  /// absente (uid inconnu = backend hérité sans claim `uid` → pas
  /// d'estampillage possible).
  void set(String? uid, {String? schoolId}) {
    _uid = (uid != null && uid.isNotEmpty) ? uid : null;
    _schoolId = (schoolId != null && schoolId.isNotEmpty) ? schoolId : null;
  }

  void clear() {
    _uid = null;
    _schoolId = null;
  }
}

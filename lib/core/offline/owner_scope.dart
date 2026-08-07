/// Partitionnement des caches de **référence cadrés enseignant** par compte,
/// sur une tablette partagée par plusieurs profs.
///
/// ## Le problème
///
/// Les pulls `schedule/sessions`, `academics/cours` et `grades-referential`
/// sont scopés **enseignant côté serveur** (dérivé du token) : chaque compte
/// reçoit un univers différent sur les mêmes tables locales, avec le même
/// curseur `sync_meta`. Sans partition :
///
///  1. le prof A tire ses séances, le curseur avance au watermark T ;
///  2. le prof B se connecte : son pull repart de T, le serveur ne renvoie que
///     ce qui a changé **après** T → page vide → `304`. Les séances de B, plus
///     anciennes, n'arrivent jamais ;
///  3. B voit la grille de A, ou rien du tout — définitivement.
///
/// ## Le choix : partitionner, pas purger
///
/// Purger les caches au changement de compte réglerait la collision, mais
/// casserait l'offline-first : dans un cycle A → B → A hors ligne, A
/// retrouverait une app vide et ne pourrait plus travailler jusqu'à retrouver
/// du réseau. On fait donc **coexister** les comptes : curseur par compte
/// ([scopedResource]) et colonne `owner_uid` sur les lignes ([ownerKey]).
///
/// L'estampille est posée **par le client** à l'application du delta, pas
/// fournie par le serveur : puisque l'endpoint est déjà cadré enseignant, tout
/// ce qui revient d'un cycle appartient par construction au compte connecté à
/// cet instant. Aucun aller-retour de contrat n'est nécessaire — et surtout,
/// on ne dépend pas de `teachers.user_id` côté back (lien nullable et
/// modifiable : le dénormaliser sur chaque ligne obligerait à tout ré-estamper
/// le jour où il change).
///
/// **Ce n'est pas une frontière de sécurité** : les lignes des autres comptes
/// restent présentes dans la même base chiffrée, simplement filtrées. C'est le
/// compromis assumé d'un cache de device partagé (comme `CurrentUserContext`,
/// dont la doc rappelle que la frontière réelle est serveur).
library;

/// Propriétaire des lignes tirées par un backend qui n'expose pas le claim
/// `uid` (cas hérité prévu par `CurrentUserContext.set`). Repli explicite
/// plutôt que `NULL` : le filtre de lecture et l'estampille d'écriture restent
/// la même valeur, donc l'app fonctionne exactement comme avant la partition
/// (mono-compte), sans branche conditionnelle dans les DAO.
const String kUnscopedOwnerUid = '';

/// Estampille de propriétaire à écrire sur une ligne de référence.
String ownerKey(String? uid) =>
    (uid == null || uid.isEmpty) ? kUnscopedOwnerUid : uid;

/// Clé `sync_meta` d'une ressource cadrée enseignant, partitionnée par compte.
///
/// Le séparateur `@` ne peut pas collisionner avec les clés existantes : les
/// ressources par entité utilisent `:` (`academics_evaluations:<coursId>`).
/// Un uid absent rend la clé **inchangée** — les bases héritées gardent leur
/// curseur et ne rebootstrapent pas pour rien.
String scopedResource(String base, String? uid) =>
    (uid == null || uid.isEmpty) ? base : '$base@$uid';

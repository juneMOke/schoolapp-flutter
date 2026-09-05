import 'package:school_app_flutter/core/auth/permissions.dart';

/// Issue d'un pull delta d'une ressource (diagnostic / agrégation par le
/// coordinateur). Miroir *lecture* de `OutboxDispatchResult` (qui, lui, pousse).
enum PullResult {
  /// Delta appliqué : des lignes ont été upsertées **ou retirées** localement.
  updated,

  /// Rien de plus récent côté serveur (304 / delta vide) — curseur conservé.
  notModified,

  /// Échec (réseau, payload invalide, pré-requis local manquant). Non fatal :
  /// isolé par ressource, le coordinateur poursuit les autres.
  error,
}

/// Bilan d'un pull unitaire renvoyé par un [PullHandler].
class PullOutcome {
  final PullResult result;

  /// Nombre de lignes appliquées (0 si [PullResult.notModified] / [PullResult.error]).
  final int upserted;

  /// Nombre de lignes **retirées** localement sur ce pull.
  ///
  /// Sans ce compteur, un cycle qui ne fait qu'effacer se rapporterait comme
  /// inactif : `upserted: 0` se lit « rien à faire », alors que la tablette
  /// vient de perdre des lignes — exactement l'événement qu'on veut voir dans un
  /// diagnostic, et le seul dont l'utilisateur puisse s'étonner.
  final int removed;

  /// Message d'échec ([PullResult.error] uniquement).
  final String? error;

  /// Horloge **serveur** (epoch ms) de la page ayant produit ce résultat —
  /// portée par l'enveloppe keyset (`serverTime`), jamais l'horloge device.
  /// `null` si la ressource n'a rien retourné (304 sans corps) ou n'a pas
  /// encore de `serverTime` dans son contrat (cf. `PullCoordinator`).
  final int? serverTimeMs;

  const PullOutcome._(
    this.result, {
    this.upserted = 0,
    this.removed = 0,
    this.error,
    this.serverTimeMs,
  });

  const PullOutcome.updated({
    int upserted = 0,
    int removed = 0,
    int? serverTimeMs,
  }) : this._(
         PullResult.updated,
         upserted: upserted,
         removed: removed,
         serverTimeMs: serverTimeMs,
       );

  const PullOutcome.notModified() : this._(PullResult.notModified);

  const PullOutcome.error(String error)
    : this._(PullResult.error, error: error);
}

/// Contrat qu'un module offline implémente pour **tirer (pull delta)** sa
/// ressource de référence depuis le serveur et peupler le cache local.
///
/// Miroir *lecture* de `OutboxSyncHandler` (qui **pousse** l'outbox). Enregistré
/// sur le [PullCoordinator] par la DI de la branche ; routé par [resource].
///
/// **Self-sufficient** : le handler résout **ses propres** paramètres (année
/// courante depuis le bootstrap local, curseur `updatedSince` via `SyncMetaDao`,
/// etc.) — le coordinateur ne les connaît pas et ne les fournit pas. Il doit
/// **ne jamais lever** : tout échec est encodé dans [PullOutcome.error] (le
/// coordinateur convertit malgré tout une exception en échec par prudence).
abstract class PullHandler {
  /// Clé de ressource (identique à celle utilisée dans `SyncMetaDao`, ex.
  /// `'classrooms'`). Sert de clé de routage et de déduplication.
  String get resource;

  /// Permission(s) de lecture exigées par le point d'entrée `/sync` de cette
  /// ressource (ADR-014). Le coordinateur saute la ressource quand la session
  /// ne les détient pas : sans ce filtre, chaque cycle de pull collectionnerait
  /// des 403 sur les domaines que le compte n'a pas à lire — bruit permanent,
  /// et un état de synchronisation qui ne distingue plus « pas le droit » d'un
  /// incident réseau.
  ///
  /// Plusieurs valeurs = **conjonction** (le point d'entrée franchit deux
  /// frontières d'autorité). Volontairement sans implémentation par défaut : un
  /// handler neuf doit déclarer son exigence, et l'oubli est une erreur de
  /// compilation plutôt qu'une ressource silencieusement non filtrée.
  ///
  /// ## ⚠️ Ce n'est PLUS l'autorité de périmètre (ADR-015 O)
  ///
  /// Quand un plan de synchronisation **valide** gouverne le cycle, cette liste
  /// n'est pas consultée : le plan décide seul ce qui descend, et un flux qu'il
  /// porte est tiré même si la session ne détient pas la permission déclarée
  /// ici. C'est tout le gain du chantier — cette liste est une copie durcie du
  /// modèle de droits, embarquée dans l'APK, qui annulait en silence tout ce que
  /// le serveur accorde par entraînement.
  ///
  /// Elle ne disparaît pas pour autant : elle devient le filtre du **mode
  /// dégradé**, celui où le plan est illisible (serveur non déployé, réseau,
  /// `subject` discordant). C'est-à-dire, aujourd'hui encore, le mode le plus
  /// courant.
  ///
  /// **Substitution, jamais union.** Si vous vous apprêtez à rétablir ce filtre
  /// à côté du plan « par prudence », relisez `PullCoordinator._runCycle` :
  /// c'est précisément ce que le `switch` sur l'état du plan rend
  /// inexprimable, et l'union des deux autorités perdrait tout le bénéfice.
  List<Perm> get requiredPermissions;

  /// Flux **socle** : garanti à tout compte authentifié, hors de tout filtre de
  /// permission (ADR-015 M).
  ///
  /// Un seul handler le surcharge — le référentiel de l'école. La porte de
  /// navigation en dépend : sans les années de référence, l'utilisateur reste
  /// sur l'écran d'amorçage et **la seule sortie est la déconnexion**. Le
  /// serveur l'a d'ailleurs tranché dans le même sens, en faisant du plan le
  /// seul flux sans garde de permission.
  ///
  /// ⚠️ **Ne JAMAIS traduire ce statut par `requiredPermissions: const []`.**
  /// `canAccess` rend `false` sur exigence vide, délibérément — « une exigence
  /// vide est presque toujours une déclaration oubliée, et un oubli doit
  /// refuser ». Le socle cesserait de descendre pour tout le parc. D'où un
  /// drapeau explicite, qui dit la chose plutôt que de la coder par une absence.
  ///
  /// Le drapeau est **permanent**, et non un échafaudage en attendant que le
  /// plan gouverne : quand le plan est illisible, `requiredPermissions` reprend
  /// la main, et sans ce drapeau le socle serait de nouveau sauté — au pire
  /// moment, celui où plus rien d'autre ne rattrape.
  bool get isBaseline => false;

  /// Exécute le pull delta et peuple le cache local. Ne lève pas.
  Future<PullOutcome> pull();
}

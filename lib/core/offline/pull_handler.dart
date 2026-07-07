/// Issue d'un pull delta d'une ressource (diagnostic / agrégation par le
/// coordinateur). Miroir *lecture* de `OutboxDispatchResult` (qui, lui, pousse).
enum PullResult {
  /// Delta appliqué : des lignes ont été upsertées localement.
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

  /// Message d'échec ([PullResult.error] uniquement).
  final String? error;

  const PullOutcome._(this.result, {this.upserted = 0, this.error});

  const PullOutcome.updated({int upserted = 0})
    : this._(PullResult.updated, upserted: upserted);

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

  /// Exécute le pull delta et peuple le cache local. Ne lève pas.
  Future<PullOutcome> pull();
}

import 'package:school_app_flutter/core/offline/outbox_entry.dart';

/// Issue du dispatch d'une entrée d'outbox.
enum OutboxDispatchOutcome {
  /// Succès : le serveur a acquitté (COMMITTED). Remap/réconciliation locale
  /// déjà appliqués par le handler. L'entrée passe ACKED.
  acked,

  /// Erreur transitoire (réseau, timeout, 5xx, 409 à rejouer après refetch) :
  /// l'entrée reste PENDING et sera re-tentée avec backoff.
  retry,

  /// Rejet métier définitif (validation serveur) : l'entrée passe SYNC_ERROR,
  /// à corriger côté présentation. Non rejouée automatiquement.
  failed,
}

/// Résultat renvoyé par un [OutboxSyncHandler].
class OutboxDispatchResult {
  final OutboxDispatchOutcome outcome;
  final String? error;

  const OutboxDispatchResult._(this.outcome, this.error);

  const OutboxDispatchResult.acked()
    : this._(OutboxDispatchOutcome.acked, null);

  const OutboxDispatchResult.retry([String? error])
    : this._(OutboxDispatchOutcome.retry, error);

  const OutboxDispatchResult.failed(String error)
    : this._(OutboxDispatchOutcome.failed, error);
}

/// Contrat qu'un module offline implémente pour pousser un type d'agrégat.
///
/// Le handler : (1) décode le payload figé de l'entrée, (2) appelle l'endpoint
/// serveur idempotent, (3) applique le remap / la réconciliation locale
/// (ids provisoires → canoniques, soldes autoritaires…), (4) renvoie l'issue.
///
/// Il est enregistré sur le [SyncEngine] via `registerHandler` par la DI de la
/// branche. Un même moteur route par [aggregateType].
abstract class OutboxSyncHandler {
  /// Type d'agrégat pris en charge (doit correspondre à
  /// `OutboxEntry.aggregateType`).
  String get aggregateType;

  /// Pousse l'agrégat et réconcilie le local. Ne lève PAS : encode l'échec
  /// dans le résultat (le moteur traite aussi les exceptions par un retry).
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry);
}

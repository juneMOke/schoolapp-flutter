import 'package:school_app_flutter/core/offline/outbox_entry.dart';

/// Issue du dispatch d'une entrée d'outbox.
enum OutboxDispatchOutcome {
  /// Succès : le serveur a acquitté (COMMITTED). Remap/réconciliation locale
  /// déjà appliqués par le handler. L'entrée passe ACKED.
  acked,

  /// Erreur transitoire (réseau, timeout, 5xx, 409 à rejouer après refetch) :
  /// l'entrée reste PENDING et sera re-tentée avec backoff.
  retry,

  /// **Attente d'une dépendance**, pas un échec (ex. paiement d'un élève dont
  /// l'inscription n'est pas encore ACKED — l'une des 2 seules arêtes du graphe,
  /// FRONT §6.3). L'entrée reste PENDING, repoussée d'un **délai fixe court**,
  /// **SANS** consommer de tentative ni de backoff, et **sans** jamais compter
  /// vers le poison. Le geste (l'argent reçu) n'est ni gaspillé ni faussement
  /// mis en `SYNC_ERROR` : il part dès que la dépendance est levée.
  blocked,

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

  /// Attente d'une dépendance non levée (cf. [OutboxDispatchOutcome.blocked]).
  const OutboxDispatchResult.blocked([String? reason])
    : this._(OutboxDispatchOutcome.blocked, reason);

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

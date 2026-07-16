import 'package:sqflite_common/sqlite_api.dart';

/// Taille de lot par défaut des apply de pull volumineux.
const int kPullApplyBatchSize = 100;

/// Applique [items] par lots de [batchSize] dans des transactions **courtes et
/// séparées** : le verrou de l'unique connexion sqflite (qui sérialise TOUT) est
/// relâché entre chaque lot, laissant les lectures UI s'intercaler. Sans ce
/// découpage, un gros payload de pull écrit dans une seule transaction gèle
/// l'écran pendant toute la durée de la transaction (symptôme observé : listing
/// figé + `database has been locked for 0:00:10`).
///
/// À réserver aux **applies de pull idempotents** (upserts `REPLACE` / LWW) :
/// une application partielle est sûre car le curseur de pull n'avance qu'après
/// l'apply complet — un lot qui lève rejoue tout, sans doublon.
///
/// NE PAS utiliser quand tout le payload doit être **atomique** :
///  - écriture métier + enfilage d'outbox (« appel/paiement confirmé ») ;
///  - `delete-all` + `insert-all` d'un remplacement complet (référentiel,
///    cohorte, grille tarifaire) — un échec au milieu laisserait un état vidé.
///
/// Une liste vide n'ouvre aucune transaction (no-op).
Future<void> applyInBatches<T>(
  Database db,
  List<T> items, {
  int batchSize = kPullApplyBatchSize,
  required Future<void> Function(Transaction txn, List<T> chunk) apply,
}) async {
  for (var start = 0; start < items.length; start += batchSize) {
    final end = start + batchSize < items.length
        ? start + batchSize
        : items.length;
    await db.transaction((txn) => apply(txn, items.sublist(start, end)));
  }
}

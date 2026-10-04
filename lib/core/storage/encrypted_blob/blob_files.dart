import 'dart:typed_data';

/// Où dorment les octets SCELLÉS d'un magasin chiffré — rien de plus : le
/// chiffrement, la clé et l'index restent à `EncryptedBlobStore`.
///
/// Deux états par pièce, comme deux fichiers : `pending` (posée, pas encore
/// engagée) puis `sealed` (engagée, lisible). Un seam pour le navigateur, qui
/// n'a pas de système de fichiers : le disque sur tablette et poste de bureau
/// (`BlobDirectory`), IndexedDB sur le web (`WebBlobFiles`).
///
/// Les identifiants reçus sont déjà validés (`BlobDirectory.isSafeId`).
abstract interface class BlobFiles {
  /// Pose les octets scellés de [id] en attente d'engagement.
  Future<void> writePending(String id, Uint8List sealed);

  /// Engage [id] : l'attente devient lisible. `false` s'il n'y avait rien.
  Future<bool> commit(String id);

  /// Abandonne l'attente de [id], sans erreur si elle n'existe pas.
  Future<void> discardPending(String id);

  /// [id] est-il engagé ?
  Future<bool> sealedExists(String id);

  /// Octets scellés de [id], ou `null` s'il n'est pas engagé.
  Future<Uint8List?> readSealed(String id);

  /// Retire [id], engagé comme en attente, sans erreur s'il n'existe pas.
  Future<void> delete(String id);

  /// Retire tout le magasin. Ne lève jamais.
  Future<void> deleteAll();

  /// Retire tout ce que l'index ne connaît pas, et toute attente. Rend le
  /// nombre de pièces retirées ; ne lève jamais.
  Future<int> reclaimOrphans({required Set<String> indexedIds});
}

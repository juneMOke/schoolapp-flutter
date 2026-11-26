import 'dart:typed_data';

import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';

/// Les octets de la photo du bon d'une dépense, dans leur magasin chiffré.
///
/// **Une copie par dépense, sous un seul nom** : la photo ne change jamais
/// (pas de remplacement en V1). Les octets scellés à la déclaration sont
/// donc à la fois ceux que l'envoi relit et ceux que le détail affiche ; sur
/// un autre poste, ce sont ceux que le téléchargement a rangés. Leur présence
/// est ce qui ouvre « Viser » (F40).
class ExpenseVoucherBlobs {
  final EncryptedBlobStore _store;

  const ExpenseVoucherBlobs(this._store);

  /// Le nom du fichier : `v_` + l'uuid de la dépense, sous les 64 caractères
  /// d'un nom sûr.
  static String idOf(String expenseId) => 'v_$expenseId';

  /// Scelle [bytes] ; `false` si rien n'a pu être écrit — l'appelant ne
  /// doit alors rien mettre en file : une déclaration sans ses octets ne
  /// partirait jamais.
  Future<bool> write(String expenseId, Uint8List bytes) async {
    final id = idOf(expenseId);
    final stored = await _store.stage(id: id, bytes: bytes);
    if (stored == null || !await _store.commit(id)) {
      await _store.discard(id);
      return false;
    }
    return true;
  }

  Future<BlobRead> read(String expenseId) => _store.read(idOf(expenseId));

  /// La photo est-elle sur ce poste ? Une panne passagère du magasin répond
  /// « non » : « Viser » reste fermé un instant, jamais ouvert sans photo.
  Future<bool> isOnDevice(String expenseId) async =>
      await read(expenseId) is BlobFound;

  Future<void> delete(String expenseId) => _store.delete(idOf(expenseId));
}

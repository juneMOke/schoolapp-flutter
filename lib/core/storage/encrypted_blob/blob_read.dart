import 'dart:typed_data';

/// Ce qu'un scellement a produit, tel que l'index doit l'enregistrer.
class StoredBlob {
  /// Empreinte du **clair**, celle que la relecture comparera.
  final String sha256Hex;

  /// Taille du clair : l'unité de la comptabilité de budget.
  final int clearSizeBytes;

  /// Taille du fichier écrit. Excède le clair de 33 octets constants (en-tête,
  /// nonce, MAC) — assez pour ne pas être ignoré sur un million de pièces, trop
  /// peu pour entrer dans un budget exprimé en gigaoctets.
  final int fileSizeBytes;

  const StoredBlob({
    required this.sha256Hex,
    required this.clearSizeBytes,
    required this.fileSizeBytes,
  });
}

/// Octets relus, et leur empreinte recalculée.
class LoadedBlob {
  final Uint8List bytes;
  final String sha256Hex;

  const LoadedBlob({required this.bytes, required this.sha256Hex});
}

/// Ce qu'une relecture a donné — et la distinction dont tout dépend : la pièce
/// est-elle **perdue**, ou le magasin n'a-t-il simplement **pas pu répondre** ?
///
/// Confondre les deux coûte des documents. L'appelant nettoie l'index sur la
/// première réponse ; s'il la recevait aussi pour un Keystore encore
/// indisponible au démarrage, un isolat qui n'a pas pu naître sous la pression
/// mémoire ou un descripteur de fichier épuisé, il détruirait des pièces
/// parfaitement intactes — et hors ligne, une pièce détruite ne se
/// retélécharge pas.
sealed class BlobRead {
  const BlobRead();
}

/// Les octets sont là, et se sont ouverts.
class BlobFound extends BlobRead {
  final LoadedBlob blob;

  const BlobFound(this.blob);
}

/// La pièce n'est plus : fichier absent, tronqué, étranger, ou scellé par une
/// clé qui n'existe plus. **Définitif** — la ligne d'index qui la désigne ne
/// désigne rien.
class BlobGone extends BlobRead {
  const BlobGone();
}

/// Le magasin n'a pas pu répondre : disque, plateforme, isolat, secure storage.
/// **Passager** — ne rien détruire sur ce constat.
class BlobUnavailable extends BlobRead {
  const BlobUnavailable();
}

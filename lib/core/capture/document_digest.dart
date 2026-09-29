import 'dart:isolate';
import 'dart:typed_data';

import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/jpeg_metadata_sanitizer.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';

/// Octets prêts à garder : métadonnées retirées, empreinte calculée.
class DocumentDigest {
  final Uint8List bytes;
  final String sha256Hex;

  const DocumentDigest({required this.bytes, required this.sha256Hex});
}

/// Prépare les octets d'une pièce. Injectable pour que les tests restent
/// synchrones ; [digestDocumentInIsolate] est la valeur de production.
typedef DocumentDigester =
    Future<DocumentDigest> Function(Uint8List bytes, DocumentMimeType type);

/// Traverse un isolat : le SHA-256 est calculé en Dart pur (sans
/// `cryptography_flutter`), soit près d'une demi-seconde pour 5 Mo sur un
/// poste de développement, bien plus sur une tablette — assez pour figer
/// l'écran sans le moindre indicateur.
Future<DocumentDigest> digestDocumentInIsolate(
  Uint8List bytes,
  DocumentMimeType type,
) => Isolate.run(() => digestDocument(bytes, type));

/// Corps du calcul : nettoie un JPEG, puis prend l'empreinte des octets
/// **nettoyés** — ce sont eux qui partiront, et que le serveur comparera.
Future<DocumentDigest> digestDocument(
  Uint8List bytes,
  DocumentMimeType type,
) async {
  final clean = type == DocumentMimeType.jpeg
      ? JpegMetadataSanitizer.sanitize(bytes)
      : bytes;
  return DocumentDigest(bytes: clean, sha256Hex: await sha256Hex(clean));
}

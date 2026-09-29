/// Scellement et ouverture des octets du cache de restitution éditique
/// (ADR-012 AM-10) — **le calcul seul**, sans disque ni base.
///
/// ## Pourquoi ce calcul ne tourne pas sur le thread d'interface
///
/// Aucune accélération matérielle n'est disponible : sans le greffon
/// `cryptography_flutter`, `Cryptography.instance` est `DartCryptography` et
/// l'AES est exécuté en Dart pur. Mesuré sur poste de développement (JIT,
/// x86) : **~4,3 Mo/s**, soit ~30 ms pour un reçu de 120 Ko et ~250 ms pour un
/// bulletin de 1 Mo — et une tablette d'administration est plus lente. Tenu sur
/// le thread d'interface, ouvrir une pièce en cache figerait le guichet
/// plusieurs dizaines d'images.
///
/// D'où [BlobCipherOffloader] : la traversée d'isolat est le comportement
/// **par défaut** ([offloadBlobCipher]), et non une optimisation qu'un
/// appelant penserait à demander. Le patron est celui de
/// `PasswordVerifierService`, qui sort Argon2id du thread d'interface pour la
/// même raison.
///
/// ## Ce que le format garantit
///
/// `ETLQ` · version · nonce (12 o) · chiffré · MAC (16 o). Trois propriétés,
/// chacune payée par un champ :
///
///  - **l'octet de version** ouvre la rotation de clé ou d'algorithme : un
///    fichier d'une version inconnue se relit comme un défaut de cache, pas
///    comme une erreur — la pièce se retélécharge ;
///  - le **MAC** d'AES-GCM détecte l'altération et la mauvaise clé ;
///  - la **donnée authentifiée** (AAD) est l'identifiant local de l'entrée :
///    déplacer un fichier sur le nom d'un autre le rend indéchiffrable. Sans
///    elle, deux pièces de la même tablette resteraient interchangeables, et
///    l'index désignerait des octets qui ne sont pas les siens.
///
/// L'empreinte SHA-256 rendue est **toujours celle du clair**, dans les deux
/// sens : c'est elle que l'index compare à la relecture, et la calculer ici
/// évite un second parcours des octets sur le thread d'interface.
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:flutter/foundation.dart';

/// Sens du calcul demandé.
enum BlobCipherMode {
  /// Clair → fichier scellé.
  seal,

  /// Fichier scellé → clair.
  open,
}

/// Signature d'un calcul du cache éditique. Un seul type de message et un seul
/// type de résultat pour les deux sens : la traversée d'isolat n'a ainsi qu'un
/// point d'entrée à connaître, donc une seule fonction de premier niveau.
@immutable
class BlobCipherRequest {
  final BlobCipherMode mode;

  /// Clé AES-256 brute (32 octets).
  final Uint8List keyBytes;

  /// Octets en clair ([BlobCipherMode.seal]) ou fichier complet, en-tête
  /// compris ([BlobCipherMode.open]).
  final Uint8List payload;

  /// Identifiant local de l'entrée d'index, lié cryptographiquement au
  /// contenu (AAD).
  final String entryId;

  const BlobCipherRequest({
    required this.mode,
    required this.keyBytes,
    required this.payload,
    required this.entryId,
  });
}

/// Résultat d'un calcul : les octets produits, et l'empreinte du **clair**.
@immutable
class BlobCipherResult {
  /// Fichier scellé (scellement) ou octets du PDF (ouverture).
  final Uint8List bytes;

  /// SHA-256 du clair, en hexadécimal minuscule.
  final String sha256Hex;

  /// Taille du clair, en octets — l'unité de la comptabilité de budget.
  final int clearSizeBytes;

  const BlobCipherResult({
    required this.bytes,
    required this.sha256Hex,
    required this.clearSizeBytes,
  });
}

/// Échec de scellement ou d'ouverture.
///
/// Volontairement **un seul type**, sans distinguer clé fausse, fichier tronqué
/// et en-tête inconnu : l'appelant n'a rien à en faire de différent — une pièce
/// illisible est un défaut de cache, et elle se retélécharge. Ne transporte
/// qu'un message, parce qu'elle traverse une frontière d'isolat.
class BlobCipherException implements Exception {
  final String message;

  const BlobCipherException(this.message);

  @override
  String toString() => 'BlobCipherException: $message';
}

/// Exécute un calcul du cache éditique. Injectable pour que les tests restent
/// synchrones et déterministes ; [offloadBlobCipher] en est la valeur par
/// défaut en production.
typedef BlobCipherOffloader =
    Future<BlobCipherResult> Function(BlobCipherRequest request);

/// Marque d'en-tête (`ETLQ`) — reconnaît un fichier du cache éditique et
/// écarte tout ce qui aurait atterri dans le répertoire par accident.
const List<int> kBlobMagic = [0x45, 0x54, 0x4C, 0x51];

/// Version du format de fichier. À incrémenter à tout changement d'algorithme,
/// de longueur de nonce ou de dérivation de clé.
const int kBlobFormatVersion = 1;

/// Longueur de l'en-tête : marque + version.
const int kBlobHeaderLength = 5;

/// Traverse un isolat. Défaut de production.
Future<BlobCipherResult> offloadBlobCipher(BlobCipherRequest request) =>
    compute(runBlobCipherTask, request, debugLabel: 'blob-cipher');

/// Corps du calcul, **de premier niveau** : c'est ce qui le rend exécutable
/// dans un isolat (une fermeture capturant son contexte ne l'est pas).
Future<BlobCipherResult> runBlobCipherTask(BlobCipherRequest request) async {
  final algorithm = AesGcm.with256bits();
  // `newSecretKeyFromBytes` refuse une clé de mauvaise longueur ici et
  // maintenant ; le constructeur `SecretKey` l'accepterait pour ne se plaindre
  // qu'au premier chiffrement, avec un message sans rapport.
  final SecretKey secretKey;
  try {
    secretKey = await algorithm.newSecretKeyFromBytes(request.keyBytes);
  } on ArgumentError {
    throw const BlobCipherException('clé de longueur inattendue');
  }
  final aad = utf8.encode(request.entryId);

  switch (request.mode) {
    case BlobCipherMode.seal:
      final box = await algorithm.encrypt(
        request.payload,
        secretKey: secretKey,
        // Nonce tiré par le paquet : sa longueur n'est jamais validée au
        // chiffrement, et un nonce mal dimensionné ne casserait qu'à la
        // relecture — une corruption silencieuse du cache.
        nonce: algorithm.newNonce(),
        aad: aad,
      );
      final body = box.concatenation();
      final sealed = Uint8List(kBlobHeaderLength + body.length)
        ..setAll(0, kBlobMagic)
        ..[kBlobMagic.length] = kBlobFormatVersion
        ..setAll(kBlobHeaderLength, body);
      return BlobCipherResult(
        bytes: sealed,
        sha256Hex: await sha256Hex(request.payload),
        clearSizeBytes: request.payload.length,
      );

    case BlobCipherMode.open:
      final nonceLength = algorithm.nonceLength;
      final macLength = algorithm.macAlgorithm.macLength;
      final body = _bodyOf(request.payload, nonceLength + macLength);
      final Uint8List clear;
      try {
        final box = SecretBox.fromConcatenation(
          body,
          nonceLength: nonceLength,
          macLength: macLength,
          // Vues sur les octets déjà lus, plutôt qu'une seconde copie de la
          // pièce entière : le tampon reste vivant le temps de l'appel.
          copy: false,
        );
        // `decrypt` promet un `List<int>` et rend, en Dart pur, une vue sur un
        // tampon PLUS GRAND que le clair (le flot de clé est arrondi au bloc).
        // Le recopier borne les octets à leur longueur utile — passer la vue
        // telle quelle exposerait du résidu de flot de clé à qui lirait son
        // `buffer`.
        clear = Uint8List.fromList(
          await algorithm.decrypt(box, secretKey: secretKey, aad: aad),
        );
      } on SecretBoxAuthenticationError {
        // Clé étrangère, octets altérés, ou fichier posé sous le nom d'une
        // autre entrée : indistinguables, et sans conséquence différente.
        throw const BlobCipherException('authentification refusée');
      } on ArgumentError {
        // `fromConcatenation` refuse en dessous de nonce + MAC : fichier
        // tronqué par un arrêt en cours d'écriture.
        throw const BlobCipherException('fichier tronqué');
      }
      return BlobCipherResult(
        bytes: clear,
        sha256Hex: await sha256Hex(clear),
        clearSizeBytes: clear.length,
      );
  }
}

/// Retire l'en-tête après l'avoir vérifié.
Uint8List _bodyOf(Uint8List file, int minimumBodyLength) {
  if (file.length < kBlobHeaderLength + minimumBodyLength) {
    throw const BlobCipherException('fichier tronqué');
  }
  for (var i = 0; i < kBlobMagic.length; i++) {
    if (file[i] != kBlobMagic[i]) {
      throw const BlobCipherException('fichier étranger au cache');
    }
  }
  if (file[kBlobMagic.length] != kBlobFormatVersion) {
    throw const BlobCipherException('version de format inconnue');
  }
  return Uint8List.sublistView(file, kBlobHeaderLength);
}

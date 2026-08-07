import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

/// Clé du magasin d'octets, et ce qu'on sait de son âge.
class EditiqueCacheKey {
  /// Clé AES-256 brute (32 octets).
  final Uint8List bytes;

  /// Vrai si la clé vient d'être créée à cet appel — donc si tout fichier
  /// présent sur le disque a été scellé avec une **autre** clé.
  final bool createdNow;

  const EditiqueCacheKey({required this.bytes, required this.createdNow});
}

/// Clé de chiffrement du cache de restitution éditique (ADR-012 AM-10).
///
/// Même patron que [DatabaseKeyService] et [DeviceIdentityService] : générée au
/// premier besoin, persistée dans le secure storage de l'OS, jamais écrite
/// ailleurs. **Distincte de la clé SQLCipher**, et ce n'est pas de la
/// coquetterie : c'est ce qui permettra à l'effacement physique de D-7 de
/// détruire les pièces sans toucher à la base — supprimer cette clé rend tout
/// fichier du cache définitivement illisible, ce qu'aucun parcours de
/// répertoire ne garantit aussi bien.
///
/// ## Clé absente, fichiers présents
///
/// Le cas n'est pas théorique : une restauration de sauvegarde Android rapporte
/// les fichiers d'application sans les préférences chiffrées, dont la clé
/// maîtresse vit dans le Keystore et ne se restaure pas. On en sort par
/// [EditiqueCacheKey.createdNow] : le magasin efface alors le répertoire, parce
/// que les octets qui s'y trouvent sont du bruit — les conserver occuperait le
/// budget avec des pièces qu'aucune clé ne rouvrira.
///
/// Une valeur stockée illisible (longueur inattendue, base64 corrompu) est
/// traitée exactement comme une clé absente : il n'existe aucun chemin de
/// récupération, et échouer laisserait le cache définitivement inutilisable.
class EditiqueCacheKeyService {
  /// AES-256.
  static const int _keyLengthBytes = 32;

  final FlutterSecureStorage _storage;

  const EditiqueCacheKeyService(this._storage);

  /// Retourne la clé existante, ou en génère et persiste une nouvelle.
  Future<EditiqueCacheKey> getOrCreate() async {
    final existing = await _storage.read(
      key: AppConstants.editiqueCacheKeyStorageKey,
    );
    final decoded = _decode(existing);
    if (decoded != null) {
      return EditiqueCacheKey(bytes: decoded, createdNow: false);
    }

    final generated = _generate();
    await _storage.write(
      key: AppConstants.editiqueCacheKeyStorageKey,
      value: base64Encode(generated),
    );
    return EditiqueCacheKey(bytes: generated, createdNow: true);
  }

  /// Détruit la clé persistée. Tout fichier du cache devient illisible **au
  /// prochain démarrage**, sans qu'un seul octet ait à être réécrit.
  ///
  /// ⚠ **Ne pas appeler directement pour effacer le cache** : passer par
  /// `EditiqueBlobStore.shredAll()`. Ce service ne connaît que le secure
  /// storage ; le magasin, lui, tient la clé en mémoire pour la durée du
  /// processus, et elle continuerait donc d'ouvrir les pièces de l'école ou du
  /// compte qu'on vient de congédier — jusqu'au prochain lancement.
  /// `shredAll()` fait les trois gestes dans l'ordre qui tient : les fichiers,
  /// la clé persistée, la clé en mémoire.
  Future<void> destroy() =>
      _storage.delete(key: AppConstants.editiqueCacheKeyStorageKey);

  /// 256 bits du générateur cryptographique de la plateforme.
  Uint8List _generate() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_keyLengthBytes, (_) => rng.nextInt(256)),
    );
  }

  static Uint8List? _decode(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    try {
      final bytes = base64Decode(stored);
      return bytes.length == _keyLengthBytes ? bytes : null;
    } on FormatException {
      return null;
    }
  }
}

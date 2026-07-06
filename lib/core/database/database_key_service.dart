import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

/// Gère la clé de chiffrement SQLCipher de la base locale.
///
/// La clé est générée au premier lancement et persistée dans le secure storage
/// de l'OS (jamais en clair ailleurs), sur le modèle de [TokenStorageService].
/// 256 bits d'entropie dérivés de deux UUID v4 (RNG cryptographique du paquet
/// `uuid`), sérialisés en 64 caractères hexadécimaux.
class DatabaseKeyService {
  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  const DatabaseKeyService(this._storage, this._uuid);

  /// Retourne la clé existante, ou en génère+persiste une nouvelle.
  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(
      key: AppConstants.sqlCipherKeyStorageKey,
    );
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final key = _generateKey();
    await _storage.write(key: AppConstants.sqlCipherKeyStorageKey, value: key);
    return key;
  }

  String _generateKey() {
    final high = _uuid.v4().replaceAll('-', '');
    final low = _uuid.v4().replaceAll('-', '');
    return '$high$low'; // 64 hex chars = 256 bits
  }
}

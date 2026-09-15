import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

/// Gère les clés de chiffrement SQLCipher des bases locales.
///
/// Chaque clé est générée au premier besoin et persistée dans le secure storage
/// de l'OS (jamais en clair ailleurs), sur le modèle de [TokenStorageService].
/// 256 bits d'entropie dérivés de deux UUID v4 (RNG cryptographique du paquet
/// `uuid`), sérialisés en 64 caractères hexadécimaux.
///
/// Trois familles depuis l'éclatement par école (MULTI_ECOLE_PLAN.md) : la clé
/// de l'appareil, une clé par école, et la clé HÉRITÉE de la base unique, qui
/// ne sert plus qu'à ouvrir ce fichier jusqu'à ce qu'une école l'adopte.
class DatabaseKeyService {
  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  const DatabaseKeyService(this._storage, this._uuid);

  /// Nom de l'entrée du secure storage portant la clé de [schoolId].
  static String schoolKeyStorageKey(String schoolId) =>
      '${AppConstants.sqlCipherSchoolKeyStoragePrefix}$schoolId';

  /// Clé de `device.db`, générée au premier besoin.
  Future<String> getOrCreateDeviceKey() =>
      _getOrCreate(AppConstants.sqlCipherDeviceKeyStorageKey);

  /// Clé du fichier de [schoolId], générée au premier besoin.
  Future<String> getOrCreateSchoolKey(String schoolId) =>
      _getOrCreate(schoolKeyStorageKey(schoolId));

  /// Clé de la base unique d'avant l'éclatement, ou `null` si ce poste n'en a
  /// jamais eu — ou l'a déjà transférée.
  Future<String?> readLegacyKey() async {
    final value = await _storage.read(key: AppConstants.sqlCipherKeyStorageKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Transfère la clé héritée à [schoolId], qui adopte le fichier qu'elle
  /// chiffre.
  ///
  /// **Écrase** une éventuelle clé de cette école : l'adoption n'a lieu que si
  /// l'école n'a pas encore de fichier, donc aucune clé existante ne chiffre
  /// rien — alors que garder l'ancienne rendrait le fichier adopté illisible.
  ///
  /// Lève [StateError] sans clé héritée : adopter un fichier qu'on ne sait pas
  /// ouvrir n'en ferait que perdre l'accès.
  Future<void> adoptLegacyKey(String schoolId) async {
    final legacy = await readLegacyKey();
    if (legacy == null) {
      throw StateError('Aucune clé héritée à transférer');
    }
    await _storage.write(key: schoolKeyStorageKey(schoolId), value: legacy);
  }

  /// Oublie la clé héritée, une fois son fichier adopté. La clé survit sous le
  /// nom de l'école : c'est la même valeur, rangée ailleurs.
  Future<void> forgetLegacyKey() =>
      _storage.delete(key: AppConstants.sqlCipherKeyStorageKey);

  Future<String> _getOrCreate(String storageKey) async {
    final existing = await _storage.read(key: storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final key = _generateKey();
    await _storage.write(key: storageKey, value: key);
    return key;
  }

  String _generateKey() {
    final high = _uuid.v4().replaceAll('-', '');
    final low = _uuid.v4().replaceAll('-', '');
    return '$high$low'; // 64 hex chars = 256 bits
  }
}

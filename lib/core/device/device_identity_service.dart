import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

/// Identifiant **d'installation**, stable pour la durée de vie de l'application
/// sur cet appareil.
///
/// Exigé par la zone Z3 du ticket provisoire (`PROV-<idAppareil>-<uuid>`,
/// RG-012-10) et par la traçabilité d'une anomalie (RG-012-16 : deux tablettes
/// peuvent encaisser hors ligne sur le même élève, encore faut-il savoir
/// laquelle).
///
/// **Généré, pas relevé.** Aucune dépendance plateforme n'est introduite pour
/// aller chercher un identifiant matériel : ceux-ci sont soit instables selon la
/// version d'Android, soit assimilables à un identifiant personnel. Le patron
/// est exactement celui de [DatabaseKeyService] — lire le secure storage, sinon
/// générer et persister.
///
/// Conséquence assumée : une réinstallation produit un nouvel identifiant. Ce
/// n'est pas un identifiant de parc, c'est une **empreinte de tirage** destinée
/// à distinguer deux tickets émis le même jour depuis deux postes.
class DeviceIdentityService {
  /// Longueur de la portion affichée sur le ticket. Assez pour distinguer les
  /// quelques postes d'une école, assez court pour rester lisible sur 80 mm.
  static const int _shortLength = 6;

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  const DeviceIdentityService(this._storage, this._uuid);

  /// Identifiant complet (uuid v4), généré et persisté au premier appel.
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: AppConstants.deviceIdStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _uuid.v4();
    await _storage.write(key: AppConstants.deviceIdStorageKey, value: id);
    return id;
  }

  /// Forme courte imprimée sur le ticket : 6 caractères hexadécimaux en
  /// majuscules, tirets retirés.
  static String shorten(String deviceId) {
    final compact = deviceId.replaceAll('-', '').toUpperCase();
    if (compact.length <= _shortLength) return compact;
    return compact.substring(0, _shortLength);
  }
}

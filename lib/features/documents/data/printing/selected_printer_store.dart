import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

/// Retient **quelle** imprimante cette tablette utilise.
///
/// ## Une propriété de l'appareil, jamais de l'utilisateur
///
/// La valeur n'est ni scopée par école ni par compte, et c'est voulu : une
/// tablette de guichet est physiquement posée à côté d'une imprimante, et ce
/// couple ne change pas parce qu'un autre caissier ouvre sa session. La lier au
/// compte obligerait chaque agent à re-choisir l'imprimante posée devant lui.
///
/// Elle survit donc à l'effacement du cache éditique, qui est un geste de
/// confidentialité — rien de confidentiel dans une adresse MAC d'imprimante.
///
/// ## Pourquoi le secure storage
///
/// Non pour le secret, mais parce que c'est le seul magasin clé/valeur déjà
/// présent dans le dépôt. Y ajouter `shared_preferences` pour une chaîne de
/// dix-sept caractères ferait entrer une dépendance de plus.
class SelectedPrinterStore {
  final FlutterSecureStorage _storage;

  const SelectedPrinterStore(this._storage);

  /// L'adresse retenue, ou `null` si aucune ne l'a été.
  ///
  /// Ne lève jamais : un magasin illisible (keystore réinitialisé après une
  /// restauration) se lit « aucune imprimante retenue », ce qui ramène au choix
  /// manuel — le pire cas acceptable. Faire remonter l'échec ferait échouer
  /// l'impression pour une raison que le guichet ne peut pas corriger.
  Future<String?> read() async {
    try {
      final value = await _storage.read(
        key: AppConstants.thermalPrinterMacStorageKey,
      );
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String macAddress) async {
    final trimmed = macAddress.trim();
    if (trimmed.isEmpty) return clear();
    try {
      await _storage.write(
        key: AppConstants.thermalPrinterMacStorageKey,
        value: trimmed,
      );
    } catch (_) {
      // Le choix reste effectif pour la session en cours ; il sera simplement
      // à refaire au prochain démarrage. Rien à dire au caissier.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: AppConstants.thermalPrinterMacStorageKey);
    } catch (_) {
      // Idem.
    }
  }
}

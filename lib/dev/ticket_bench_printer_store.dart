import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Retient l'imprimante du **banc de calage**, entre deux séances.
///
/// ## Un outil de calage, plus une préférence de production
///
/// La production ne s'en sert pas : depuis que le ticket demande l'imprimante à
/// **chaque** impression, il n'y a plus de choix à mémoriser au guichet — une
/// tablette déplacée d'un poste à l'autre sortirait sinon le reçu d'un parent
/// dans la pièce d'à côté.
///
/// Il reste utile ici, et seulement ici : caler une page de code ou une avance
/// papier demande vingt à trente envois d'affilée, et re-choisir l'imprimante à
/// chacun rendrait le banc pénible à l'usage même qui justifie son existence.
///
/// C'est pourquoi ce fichier vit dans `lib/dev/` : il porte sa clé de stockage
/// en dur, comme le reste du dossier, plutôt que d'occuper une entrée du
/// registre de production pour un outil absent du build release.
///
/// ## Pourquoi le secure storage
///
/// Non pour le secret — il n'y a rien de confidentiel dans une adresse MAC
/// d'imprimante — mais parce que c'est le seul magasin clé/valeur déjà présent
/// dans le dépôt. Y ajouter `shared_preferences` pour une chaîne de dix-sept
/// caractères ferait entrer une dépendance de plus.
class TicketBenchPrinterStore {
  /// Clé du magasin. Distincte de tout ce que la production écrit, et sans
  /// conséquence si elle traîne sur une tablette de développement.
  static const String _key = 'ticket_bench_printer_mac';

  final FlutterSecureStorage _storage;

  const TicketBenchPrinterStore(this._storage);

  /// L'adresse retenue, ou `null` si aucune ne l'a été.
  ///
  /// Ne lève jamais : un magasin illisible (keystore réinitialisé après une
  /// restauration) se lit « aucune imprimante retenue », ce qui ramène au choix
  /// manuel — le pire cas acceptable.
  Future<String?> read() async {
    try {
      final value = await _storage.read(key: _key);
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
      await _storage.write(key: _key, value: trimmed);
    } catch (_) {
      // Le choix reste effectif pour la séance en cours ; il sera simplement à
      // refaire au prochain démarrage.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Idem.
    }
  }
}

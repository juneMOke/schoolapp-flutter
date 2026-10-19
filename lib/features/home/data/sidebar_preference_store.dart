import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Le choix « barre latérale déployée / repliée » de ce poste, gardé d'une
/// session à l'autre : sans lui, chaque ouverture rendait la barre par défaut
/// et l'utilisateur la repliait de nouveau.
///
/// Rangé dans le stockage sécurisé faute d'autre magasin de préférences sur
/// toutes les plateformes ; la valeur n'a rien de secret.
class SidebarPreferenceStore {
  static const _key = 'ui.sidebar_expanded';

  final FlutterSecureStorage _storage;

  const SidebarPreferenceStore(this._storage);

  /// `null` : aucun choix encore fait sur ce poste, ou lecture impossible.
  Future<bool?> read() async {
    try {
      return switch (await _storage.read(key: _key)) {
        'true' => true,
        'false' => false,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  /// Une écriture en échec n'empêche rien : la barre garde l'état choisi.
  Future<void> write({required bool expanded}) async {
    try {
      await _storage.write(key: _key, value: '$expanded');
    } catch (_) {}
  }
}

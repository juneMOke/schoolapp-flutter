import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/storage/serialized_secure_storage.dart';

/// `FlutterSecureStorage` dont chaque clé est préfixée par l'environnement.
///
/// Le poste de bureau n'a qu'un trousseau par plateforme (cf.
/// `desktopIsolatedEnvironment`) : sans préfixe, une staging installée à côté
/// de la production lisait — et écrasait — la session, les clés de base et
/// les préférences de la production.
///
/// Réservé aux environnements HORS production : la production n'est jamais
/// enveloppée, ses clés restent celles d'aujourd'hui.
///
/// [readAll] et [deleteAll] ne voient que les entrées de l'environnement : un
/// `deleteAll` de la staging n'efface rien d'autre.
class EnvScopedSecureStorage extends FlutterSecureStorage {
  EnvScopedSecureStorage(this._inner, {required String environment})
    : prefix = '$environment::';

  final FlutterSecureStorage _inner;

  /// Préfixe ajouté à chaque clé, p. ex. `staging::`.
  final String prefix;

  String _scoped(String key) => '$prefix$key';

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _inner.write(
    key: _scoped(key),
    value: value,
    iOptions: iOptions,
    aOptions: aOptions,
    lOptions: lOptions,
    webOptions: webOptions,
    mOptions: mOptions,
    wOptions: wOptions,
  );

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _inner.read(
    key: _scoped(key),
    iOptions: iOptions,
    aOptions: aOptions,
    lOptions: lOptions,
    webOptions: webOptions,
    mOptions: mOptions,
    wOptions: wOptions,
  );

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _inner.containsKey(
    key: _scoped(key),
    iOptions: iOptions,
    aOptions: aOptions,
    lOptions: lOptions,
    webOptions: webOptions,
    mOptions: mOptions,
    wOptions: wOptions,
  );

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _inner.delete(
    key: _scoped(key),
    iOptions: iOptions,
    aOptions: aOptions,
    lOptions: lOptions,
    webOptions: webOptions,
    mOptions: mOptions,
    wOptions: wOptions,
  );

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final all = await _inner.readAll(
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
    return {
      for (final entry in all.entries)
        if (entry.key.startsWith(prefix))
          entry.key.substring(prefix.length): entry.value,
    };
  }

  /// N'efface QUE les entrées de cet environnement — jamais celles de la
  /// production rangées dans le même trousseau.
  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final all = await _inner.readAll(
      iOptions: iOptions,
      aOptions: aOptions,
      lOptions: lOptions,
      webOptions: webOptions,
      mOptions: mOptions,
      wOptions: wOptions,
    );
    // Copie : selon l'implémentation, `readAll` peut rendre la carte vivante
    // que chaque `delete` modifie.
    final scopedKeys = all.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in scopedKeys) {
      await _inner.delete(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    }
  }

  @override
  void registerListener({
    required String key,
    required ValueChanged<String?> listener,
  }) => _inner.registerListener(key: _scoped(key), listener: listener);

  @override
  void unregisterListener({
    required String key,
    required ValueChanged<String?> listener,
  }) => _inner.unregisterListener(key: _scoped(key), listener: listener);

  @override
  void unregisterAllListenersForKey({required String key}) =>
      _inner.unregisterAllListenersForKey(key: _scoped(key));

  @override
  void unregisterAllListeners() => _inner.unregisterAllListeners();
}

/// Le stockage sécurisé de l'application.
///
/// Windows : sérialisé (cf. `SerializedSecureStorage`). Poste hors production
/// ([isolatedEnvironment] non nul) : préfixé par l'environnement. Production
/// et tablette : le greffon tel quel, comme avant.
FlutterSecureStorage createAppSecureStorage({
  required TargetPlatform platform,
  required String? isolatedEnvironment,
}) {
  final FlutterSecureStorage base = platform == TargetPlatform.windows
      ? SerializedSecureStorage()
      : const FlutterSecureStorage();
  return isolatedEnvironment == null
      ? base
      : EnvScopedSecureStorage(base, environment: isolatedEnvironment);
}

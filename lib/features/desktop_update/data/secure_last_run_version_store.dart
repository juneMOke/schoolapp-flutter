import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/last_run_version_store.dart';

/// La dernière version lancée sur ce poste, dans le trousseau.
class SecureLastRunVersionStore implements LastRunVersionStore {
  final FlutterSecureStorage _storage;

  const SecureLastRunVersionStore(this._storage);

  static const _key = 'desktop_update_last_run_version';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String version) =>
      _storage.write(key: _key, value: version);
}

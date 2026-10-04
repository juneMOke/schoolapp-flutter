import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/storage/serialized_secure_storage.dart';

/// Le greffon Windows, rejoué : UN fichier pour toutes les clés, relu puis
/// réécrit en entier à chaque écriture, sans verrou — et des attentes entre
/// les deux, comme les entrées-sorties réelles.
class _SingleFileWindowsPlatform extends FlutterSecureStoragePlatform {
  Map<String, String> _file = {};

  Future<Map<String, String>> _load() async {
    await Future<void>.delayed(Duration.zero);
    return Map.of(_file);
  }

  Future<void> _save(Map<String, String> map) async {
    await Future<void>.delayed(Duration.zero);
    _file = map;
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    final map = await _load();
    map[key] = value;
    await _save(map);
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => (await _load())[key];

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => (await _load()).containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    final map = await _load();
    map.remove(key);
    await _save(map);
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) =>
      _load();

  @override
  Future<void> deleteAll({required Map<String, String> options}) => _save({});
}

/// La session s'écrit en douze `write` parallèles. Sur le fichier unique de
/// Windows, sans file d'attente, le jeton d'accès s'y perdait : la requête
/// suivante partait sans `Authorization`, et le serveur répondait 403.
void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = _SingleFileWindowsPlatform();
  });

  final keys = [for (var i = 0; i < 12; i++) 'k$i'];

  Future<void> writeAllInParallel(FlutterSecureStorage storage) =>
      Future.wait([for (final k in keys) storage.write(key: k, value: 'v-$k')]);

  test('le greffon nu perd des clés sous écritures parallèles', () async {
    const storage = FlutterSecureStorage();

    await writeAllInParallel(storage);

    expect((await storage.readAll()).length, lessThan(keys.length));
  });

  test('en file, toutes les clés écrites en parallèle survivent', () async {
    final storage = SerializedSecureStorage();

    await writeAllInParallel(storage);

    expect(await storage.readAll(), {for (final k in keys) k: 'v-$k'});
  });

  test('une lecture lancée après les écritures les voit toutes', () async {
    final storage = SerializedSecureStorage();

    final writes = writeAllInParallel(storage);
    final read = storage.read(key: 'k11');
    await writes;

    expect(await read, 'v-k11');
  });

  test('un échec ne bloque pas la file', () async {
    final storage = SerializedSecureStorage();
    FlutterSecureStoragePlatform.instance = _FailingOncePlatform();

    await expectLater(
      storage.write(key: 'a', value: '1'),
      throwsA(isA<StateError>()),
    );
    await storage.write(key: 'b', value: '2');

    expect(await storage.read(key: 'b'), '2');
  });
}

class _FailingOncePlatform extends _SingleFileWindowsPlatform {
  var _failed = false;

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) {
    if (!_failed) {
      _failed = true;
      throw StateError('disque plein');
    }
    return super.write(key: key, value: value, options: options);
  }
}

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/database/tenant/offline_database_files.dart';
import 'package:school_app_flutter/core/database/tenant/unreadable_device_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// Une clé perdue, sur de vrais fichiers : l'ouvreur ffi de test ne chiffre
/// pas, un fichier qui n'est pas une base produit donc la même réponse du
/// moteur qu'une mauvaise clé — `SQLITE_NOTADB`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late Map<String, String> stored;
  late List<Database> opened;
  late OfflineDatabaseFiles files;

  Future<Database> ffiOpen(
    String path, {
    required String key,
    required int version,
    required OnDatabaseCreateFn onCreate,
    required OnDatabaseVersionChangeFn onUpgrade,
  }) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        singleInstance: false,
      ),
    );
    opened.add(db);
    return db;
  }

  String inDir(String name) => p.join(dir.path, name);

  Future<void> scramble(String path) =>
      File(path).writeAsBytes(List<int>.generate(4096, (i) => i * 7 % 251));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('unreadable_device_');
    stored = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(stored);
    opened = <Database>[];
    files = OfflineDatabaseFiles(
      directory: dir.path,
      keys: const DatabaseKeyService(FlutterSecureStorage(), Uuid()),
      open: ffiOpen,
    );
  });

  tearDown(() async {
    for (final db in opened) {
      if (db.isOpen) await db.close();
    }
    await dir.delete(recursive: true);
  });

  test(
    'un device.db qui ne se déchiffre pas lève l exception dédiée',
    () async {
      await scramble(files.devicePath);

      await expectLater(
        files.openDevice(),
        throwsA(isA<UnreadableDeviceDatabaseException>()),
      );
    },
  );

  test('une autre panne d ouverture remonte telle quelle', () async {
    await Directory(files.devicePath).create();

    await expectLater(
      files.openDevice(),
      throwsA(isNot(isA<UnreadableDeviceDatabaseException>())),
    );
  });

  test('l effacement garde les bases dont la clé survit, puis device.db se '
      'recrée', () async {
    await scramble(files.devicePath);
    await File('${files.devicePath}-wal').writeAsString('x');
    await File(files.schoolPath('keyed')).writeAsString('x');
    await File(files.schoolPath('lost')).writeAsString('x');
    await File(inDir(AppConstants.offlineDbName)).writeAsString('x');
    await File(inDir('autre.txt')).writeAsString('x');
    stored[DatabaseKeyService.schoolKeyStorageKey('keyed')] = 'k';
    FlutterSecureStorage.setMockInitialValues(stored);

    late UnreadableDeviceDatabaseException error;
    try {
      await files.openDevice();
    } on UnreadableDeviceDatabaseException catch (e) {
      error = e;
    }
    await error.discardUnreadableFiles();

    final left = dir.listSync().map((e) => p.basename(e.path)).toSet();
    expect(left, {p.basename(files.schoolPath('keyed')), 'autre.txt'});
    final device = await files.openDevice();
    expect(device.isOpen, isTrue);
  });

  test('la base héritée est gardée tant que sa clé existe', () async {
    await File(inDir(AppConstants.offlineDbName)).writeAsString('x');
    stored[AppConstants.sqlCipherKeyStorageKey] = 'legacy';
    FlutterSecureStorage.setMockInitialValues(stored);

    await files.discardUnreadableFiles();

    expect(File(inDir(AppConstants.offlineDbName)).existsSync(), isTrue);
  });
}

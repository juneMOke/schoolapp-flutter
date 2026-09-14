import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/legacy_database_split.dart';
import 'package:school_app_flutter/core/database/tenant/offline_database_files.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

Map<String, Object?> _user(String uid, String school, {int lastSeen = 1}) => {
  'user_id': uid,
  'email': '$uid@x.cd',
  'first_name': 'F',
  'last_name': 'L',
  'role': 'CASHIER',
  'school_id': school,
  'password_verifier': 'v',
  'verifier_salt': 's',
  'user_version': 1,
  'first_online_login_at': 1,
  'last_server_seen_at': lastSeen,
};

Future<Set<String>> _tables(Database db) async => {
  for (final row in await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  ))
    row['name']! as String,
};

Future<int> _userVersion(Database db) async =>
    (await db.rawQuery('PRAGMA user_version')).first.values.first! as int;

/// Les fichiers réels du poste, sur disque, derrière un ouvreur ffi : c'est la
/// seule façon d'exercer le renommage et l'adoption tels qu'ils se passent sur
/// une tablette (MULTI_ECOLE_PLAN.md §10.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late Map<String, String> stored;
  late DatabaseKeyService keys;
  late Map<String, String> keyUsedFor;
  late List<Database> opened;
  late OfflineDatabaseFiles files;

  Future<Database> ffiOpen(
    String path, {
    required String key,
    required int version,
    required OnDatabaseCreateFn onCreate,
    required OnDatabaseVersionChangeFn onUpgrade,
  }) async {
    keyUsedFor[p.basename(path)] = key;
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        singleInstance: false,
      ),
    );
    opened.add(db);
    return db;
  }

  String legacyPath() => p.join(dir.path, AppConstants.offlineDbName);

  /// Une base héritée v48 comme celles du parc : schéma complet, clé héritée.
  Future<void> seedLegacy({
    required List<Map<String, Object?>> users,
    String? sessionUserId,
    List<String> pendingAuthors = const [],
    Map<String, String> cursors = const {},
    bool withKey = true,
  }) async {
    if (withKey) {
      stored[AppConstants.sqlCipherKeyStorageKey] = 'legacy-key';
      FlutterSecureStorage.setMockInitialValues(stored);
    }
    final legacy = await databaseFactoryFfi.openDatabase(
      legacyPath(),
      options: OpenDatabaseOptions(
        version: AppConstants.legacyOfflineDbSchemaVersion,
        onCreate: (db, _) => createOfflineSchema(db, buildOfflineSchema()),
        singleInstance: false,
      ),
    );
    for (final user in users) {
      await legacy.insert('auth_local_user', user);
    }
    if (sessionUserId != null) {
      await legacy.insert('auth_local_session', {
        'id': 1,
        'user_id': sessionUserId,
        'refresh_expires_at': 99,
        'last_evaluated_at': 1,
      });
    }
    var n = 0;
    for (final author in pendingAuthors) {
      n++;
      await legacy.insert('outbox', {
        'id': 'o$n',
        'aggregate_type': 'PAYMENT',
        'aggregate_id': 'p$n',
        'operation': 'create',
        'payload': jsonEncode({'authorId': author}),
        'created_at': n,
      });
    }
    await legacy.insert('editique_cache_entries', {
      'id': 'e1',
      'document_id': 'doc-1',
      'doc_type': 'RC',
      'school_id': 'school-b',
      'size_bytes': 10,
      'created_at': 1,
      'last_accessed_at': 1,
    });
    for (final cursor in cursors.entries) {
      await legacy.insert('sync_meta', {
        'resource': cursor.key,
        'cursor': cursor.value,
        'synced_at': 1,
      });
    }
    await legacy.close();
  }

  /// Le cas du staging : deux écoles, la session sur A, une écriture de B en
  /// attente.
  Future<void> seedStagingLegacy() => seedLegacy(
    users: [_user('uid-a', 'school-a'), _user('uid-b', 'school-b')],
    sessionUserId: 'uid-a',
    pendingAuthors: ['uid-b'],
    cursors: {
      'editique_documents@school-b': 'c-doc',
      'editique_cache_school': 'school-b',
      'enrollments': 'c-enr',
    },
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('multi_ecole_files_');
    stored = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(stored);
    keys = const DatabaseKeyService(FlutterSecureStorage(), Uuid());
    keyUsedFor = <String, String>{};
    opened = <Database>[];
    files = OfflineDatabaseFiles(
      directory: dir.path,
      keys: keys,
      open: ffiOpen,
    );
  });

  tearDown(() async {
    for (final db in opened) {
      if (db.isOpen) await db.close();
    }
    await dir.delete(recursive: true);
  });

  group('poste neuf', () {
    test('device.db au schéma de l appareil, rien à éclater', () async {
      final device = await files.openDevice();

      expect(
        await _tables(device),
        containsAll(buildDeviceSchema().map((t) => t.name)),
      );
      expect(await _tables(device), isNot(contains('outbox')));
      expect(await readDeviceMeta(device, kLegacyStateKey), isNull);
    });

    test('chaque école reçoit son fichier, sous sa clé, en v49', () async {
      final device = await files.openDevice();

      final a = await files.openSchool('school-a', device: device);
      final b = await files.openSchool('school-b', device: device);

      expect(await _tables(a), contains('outbox'));
      expect(await _tables(a), isNot(contains('auth_local_user')));
      expect(await _userVersion(a), AppConstants.offlineDbSchemaVersion);
      expect(
        keyUsedFor['school_school-a.db'],
        isNot(keyUsedFor['school_school-b.db']),
      );
      await a.insert('sync_meta', {'resource': 'enrollments', 'cursor': 'A'});
      expect(await b.query('sync_meta'), isEmpty);
    });

    test('rouvrir une école rend SON fichier, pas un neuf', () async {
      final device = await files.openDevice();
      final first = await files.openSchool('school-a', device: device);
      await first.insert('sync_meta', {'resource': 'r', 'cursor': 'kept'});
      await first.close();

      final again = await files.openSchool('school-a', device: device);

      expect((await again.query('sync_meta')).single['cursor'], 'kept');
    });
  });

  group('éclatement de la base héritée', () {
    test('comptes, session, index éditique et ses curseurs passent à '
        'l appareil ; la base héritée n est pas touchée', () async {
      await seedStagingLegacy();

      final device = await files.openDevice();

      expect(await device.query('auth_local_user'), hasLength(2));
      expect(
        (await device.query('auth_local_session')).single['user_id'],
        'uid-a',
      );
      expect(await device.query('editique_cache_entries'), hasLength(1));
      expect(
        (await device.query('sync_meta')).map((r) => r['resource']).toList(),
        ['editique_documents@school-b'],
      );
      expect(await readDeviceMeta(device, kLegacyStateKey), kLegacyStateSplit);
      // L'argent d'abord : l'écriture de B en attente désigne B, pas la
      // session de A.
      expect(await readDeviceMeta(device, kLegacyOwnerKey), 'school-b');
      expect(await File(legacyPath()).exists(), isTrue);
    });

    test('rejoué, il ne double rien', () async {
      await seedStagingLegacy();
      final first = await files.openDevice();
      await first.close();

      final device = await files.openDevice();

      expect(await device.query('auth_local_user'), hasLength(2));
    });

    test('un compte déjà connu de l appareil garde SA ligne : elle vient '
        'd un login plus récent', () async {
      await seedStagingLegacy();
      // Premier démarrage où l'éclatement a échoué, puis login en ligne de A.
      stored.remove(AppConstants.sqlCipherKeyStorageKey);
      FlutterSecureStorage.setMockInitialValues(stored);
      final early = await files.openDevice();
      await early.insert(
        'auth_local_user',
        _user('uid-a', 'school-a', lastSeen: 777),
      );
      await early.close();
      stored[AppConstants.sqlCipherKeyStorageKey] = 'legacy-key';
      FlutterSecureStorage.setMockInitialValues(stored);

      final device = await files.openDevice();

      final a = await device.query(
        'auth_local_user',
        where: 'user_id = ?',
        whereArgs: ['uid-a'],
      );
      expect(a.single['last_server_seen_at'], 777);
    });

    test('sans clé héritée : laissée en place, jamais adoptée, jamais '
        'effacée', () async {
      await seedStagingLegacy();
      stored.remove(AppConstants.sqlCipherKeyStorageKey);
      FlutterSecureStorage.setMockInitialValues(stored);

      final device = await files.openDevice();
      final school = await files.openSchool('school-b', device: device);

      expect(await readDeviceMeta(device, kLegacyStateKey), isNull);
      expect(await school.query('outbox'), isEmpty);
      expect(await File(legacyPath()).exists(), isTrue);
    });
  });

  group('adoption', () {
    test('le propriétaire adopte : même fichier, même clé, tables de '
        'l appareil rendues', () async {
      await seedStagingLegacy();
      final device = await files.openDevice();

      final school = await files.openSchool('school-b', device: device);

      expect(await File(legacyPath()).exists(), isFalse);
      expect(keyUsedFor['school_school-b.db'], 'legacy-key');
      expect(await school.query('outbox'), hasLength(1));
      expect(
        (await school.query('sync_meta')).map((r) => r['resource']).toList(),
        ['enrollments'],
      );
      expect(await _tables(school), isNot(contains('auth_local_user')));
      expect(await _tables(school), isNot(contains('editique_cache_entries')));
      expect(await _userVersion(school), AppConstants.offlineDbSchemaVersion);
      expect(
        await readDeviceMeta(device, kLegacyStateKey),
        kLegacyStateAdopted,
      );
      expect(await keys.readLegacyKey(), isNull);
      expect(await keys.getOrCreateSchoolKey('school-b'), 'legacy-key');
    });

    test('une autre école reçoit un fichier neuf et laisse la base héritée à '
        'son propriétaire', () async {
      await seedStagingLegacy();
      final device = await files.openDevice();

      final school = await files.openSchool('school-a', device: device);

      expect(await school.query('outbox'), isEmpty);
      expect(await File(legacyPath()).exists(), isTrue);
      expect(await readDeviceMeta(device, kLegacyStateKey), kLegacyStateSplit);
    });

    test('sans aucun compte, la première école qui ouvre une session '
        'adopte', () async {
      await seedLegacy(users: const [], cursors: {'enrollments': 'c-enr'});
      final device = await files.openDevice();

      final school = await files.openSchool('school-z', device: device);

      expect(await File(legacyPath()).exists(), isFalse);
      expect(await school.query('sync_meta'), hasLength(1));
    });

    test('coupée après le transfert de clé, l adoption se reprend', () async {
      await seedStagingLegacy();
      final device = await files.openDevice();
      await keys.adoptLegacyKey('school-b');

      final school = await files.openSchool('school-b', device: device);

      expect(await school.query('outbox'), hasLength(1));
      expect(
        await readDeviceMeta(device, kLegacyStateKey),
        kLegacyStateAdopted,
      );
    });

    test('coupée après le renommage, le fichier s ouvre et la note se '
        'rattrape', () async {
      await seedStagingLegacy();
      final device = await files.openDevice();
      await keys.adoptLegacyKey('school-b');
      await File(legacyPath()).rename(files.schoolPath('school-b'));

      final school = await files.openSchool('school-b', device: device);
      // Le fichier existait déjà : la note se rattrape à la prochaine école
      // qui cherche la base héritée.
      await files.openSchool('school-a', device: device);

      expect(await school.query('outbox'), hasLength(1));
      expect(
        await readDeviceMeta(device, kLegacyStateKey),
        kLegacyStateAdopted,
      );
    });

    test('un éclatement jamais abouti est retenté à l ouverture de l école, '
        'avant tout fichier neuf', () async {
      await seedStagingLegacy();
      final device = await databaseFactoryFfi.openDatabase(
        files.devicePath,
        options: OpenDatabaseOptions(
          version: AppConstants.offlineDbSchemaVersion,
          onCreate: (db, _) => createOfflineSchema(db, buildDeviceSchema()),
          singleInstance: false,
        ),
      );
      opened.add(device);

      final school = await files.openSchool('school-b', device: device);

      expect(await school.query('outbox'), hasLength(1));
    });
  });

  test('un identifiant qui ne peut pas être un nom de fichier est refusé', () {
    expect(() => files.schoolPath('../x'), throwsArgumentError);
    expect(() => files.schoolPath(''), throwsArgumentError);
    // `school_offline.db` est le nom de la base héritée.
    expect(() => files.schoolPath('offline'), throwsArgumentError);
  });
}

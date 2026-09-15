import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/database/tenant/offline_database_files.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_database.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_scope.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// L'école de la session, sur de vrais fichiers (MULTI_ECOLE_PLAN.md §10.2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late List<Database> opened;
  late List<String> openedPaths;
  late OfflineDatabaseFiles files;
  late Database device;
  late TenantDatabase tenant;
  late int hookRuns;

  Future<Database> ffiOpen(
    String path, {
    required String key,
    required int version,
    required OnDatabaseCreateFn onCreate,
    required OnDatabaseVersionChangeFn onUpgrade,
  }) async {
    openedPaths.add(path);
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

  TenantSession session({List<TenantAttachedHook> hooks = const []}) =>
      TenantSession(
        tenant: tenant,
        files: files,
        device: device,
        onAttached: hooks,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('multi_ecole_session_');
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    opened = <Database>[];
    openedPaths = <String>[];
    files = OfflineDatabaseFiles(
      directory: dir.path,
      keys: const DatabaseKeyService(FlutterSecureStorage(), Uuid()),
      open: ffiOpen,
    );
    device = await files.openDevice();
    openedPaths.clear();
    tenant = TenantDatabase();
    hookRuns = 0;
  });

  tearDown(() async {
    for (final db in opened) {
      if (db.isOpen) await db.close();
    }
    await dir.delete(recursive: true);
  });

  test('attacher ouvre le fichier de l école, et le proxy le sert', () async {
    await session().attach('school-a');

    expect(tenant.schoolId, 'school-a');
    await tenant.insert('sync_meta', {'resource': 'r', 'cursor': 'A'});
    expect(openedPaths.single, files.schoolPath('school-a'));
  });

  test('la même école deux fois : un seul fichier ouvert', () async {
    final s = session();

    await s.attach('school-a');
    await s.attach('school-a');

    expect(openedPaths, hasLength(1));
  });

  test('A → B → A : chaque école retrouve SES lignes, et A n est pas '
      'rouverte', () async {
    final s = session();
    await s.attach('school-a');
    await tenant.insert('sync_meta', {
      'resource': 'enrollments',
      'cursor': 'A',
    });
    await s.attach('school-b');
    expect(await tenant.query('sync_meta'), isEmpty);
    await tenant.insert('sync_meta', {
      'resource': 'enrollments',
      'cursor': 'B',
    });

    await s.attach('school-a');

    expect((await tenant.query('sync_meta')).single['cursor'], 'A');
    expect(openedPaths, hasLength(2));
  });

  test(
    'deux attachements concurrents de la même école : une connexion',
    () async {
      final s = session();

      await Future.wait([s.attach('school-a'), s.attach('school-a')]);

      expect(openedPaths, hasLength(1));
    },
  );

  test(
    'la reprise se rejoue à chaque attachement, pas à chaque appel',
    () async {
      final s = session(hooks: [() async => hookRuns++]);

      await s.attach('school-a');
      await s.attach('school-a');
      await s.attach('school-b');

      expect(hookRuns, 2);
    },
  );

  test('une reprise qui échoue ne refuse pas la session', () async {
    final s = session(hooks: [() async => throw StateError('reprise')]);

    await s.attach('school-a');

    expect(tenant.schoolId, 'school-a');
  });

  test('détacher : plus aucun accès métier', () async {
    final s = session();
    await s.attach('school-a');

    await s.detach();

    await expectLater(
      tenant.query('sync_meta'),
      throwsA(isA<NoTenantAttachedException>()),
    );
  });

  test('une session sans école n écrit dans aucune — surtout pas la '
      'précédente', () async {
    final s = session();
    await s.attach('school-a');

    await s.attach('');

    expect(tenant.isAttached, isFalse);
  });

  test('un attachement refusé lève, et n empêche pas le suivant', () async {
    final s = session();

    await expectLater(s.attach('../evasion'), throwsArgumentError);
    await s.attach('school-a');

    expect(tenant.schoolId, 'school-a');
  });

  test('PinnedTenantSession ne touche à rien', () async {
    const pinned = PinnedTenantSession();

    await pinned.attach('school-a');
    await pinned.detach();

    expect(tenant.isAttached, isFalse);
  });
}

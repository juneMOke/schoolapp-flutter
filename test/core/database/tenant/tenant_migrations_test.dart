import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Set<String>> _tables(Database db) async => {
  for (final row in await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  ))
    row['name']! as String,
};

/// Le palier v49 d'une base héritée adoptée : elle rend à l'appareil ses
/// tables, et garde tout le reste.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute('PRAGMA foreign_keys = ON');
    await createOfflineSchema(db, buildOfflineSchema());

    await db.insert('auth_local_user', {
      'user_id': 'uid-a',
      'email': 'a@x.cd',
      'first_name': 'A',
      'last_name': 'A',
      'role': 'CASHIER',
      'school_id': 'A',
      'password_verifier': 'v',
      'verifier_salt': 's',
      'user_version': 1,
      'first_online_login_at': 1,
      'last_server_seen_at': 1,
    });
    await db.insert('auth_local_session', {
      'id': 1,
      'user_id': 'uid-a',
      'refresh_expires_at': 99,
      'last_evaluated_at': 1,
    });
    await db.insert('editique_cache_entries', {
      'id': 'e1',
      'document_id': 'doc-1',
      'doc_type': 'RC',
      'school_id': 'A',
      'size_bytes': 10,
      'created_at': 1,
      'last_accessed_at': 1,
    });
    for (final resource in [
      'editique_documents@A',
      'editique_cache_school',
      'enrollments',
    ]) {
      await db.insert('sync_meta', {'resource': resource, 'cursor': 'c'});
    }
    await db.insert('outbox', {
      'id': 'o1',
      'aggregate_type': 'PAYMENT',
      'aggregate_id': 'p1',
      'operation': 'create',
      'payload': '{}',
      'created_at': 1,
    });
  });

  tearDown(() => db.close());

  test('retire les tables de l appareil, session d abord malgré la clé '
      'étrangère', () async {
    await migrateTenantDatabase(db, 48);

    final tables = await _tables(db);
    expect(tables, isNot(contains('auth_local_user')));
    expect(tables, isNot(contains('auth_local_session')));
    expect(tables, isNot(contains('editique_cache_entries')));
  });

  test('les curseurs éditique partent avec l index ; ceux de l école '
      'restent', () async {
    await migrateTenantDatabase(db, 48);

    final resources = (await db.query(
      'sync_meta',
    )).map((r) => r['resource']).toList();
    expect(resources, ['enrollments']);
  });

  test('l outbox reste : ce sont les écritures de cette école', () async {
    await migrateTenantDatabase(db, 48);

    expect(await db.query('outbox'), hasLength(1));
  });

  test('rejouable sans dommage', () async {
    await migrateTenantDatabase(db, 48);
    await migrateTenantDatabase(db, 48);

    expect(await db.query('outbox'), hasLength(1));
  });
}

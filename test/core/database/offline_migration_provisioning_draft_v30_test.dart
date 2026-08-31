import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v29 → v30 : `provisioning_drafts`, le brouillon de mise en service.
///
/// Création pure, sans backfill — rien dans la base ne s'y rattachait. Ce que ce
/// test protège, c'est qu'un appareil déjà en service la reçoive : sans la
/// table, l'assistant perdrait la saisie à chaque fermeture de l'application, et
/// l'échec serait silencieux (une écriture qui lève, une lecture qui rend null).
bool _ffiInitialized = false;

Future<Database> _openV29Db() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  // Base v29 : tout le schéma SAUF la table du module Configuration.
  for (final table in buildOfflineSchema()) {
    if (table.name == 'provisioning_drafts') continue;
    await db.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      await db.execute(indexSql);
    }
  }
  return db;
}

Future<bool> _hasTable(Database db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [table],
  );
  return rows.isNotEmpty;
}

void main() {
  late Database db;

  setUp(() async => db = await _openV29Db());
  tearDown(() async => db.close());

  test('v29 → v30 crée la table du brouillon', () async {
    expect(await _hasTable(db, 'provisioning_drafts'), isFalse);

    await migrateOfflineDatabase(db, 29, buildOfflineSchema(), newVersion: 30);

    expect(await _hasTable(db, 'provisioning_drafts'), isTrue);
  });

  test('l\'étape est idempotente au rejeu', () async {
    await migrateOfflineDatabase(db, 29, buildOfflineSchema(), newVersion: 30);
    await migrateOfflineDatabase(db, 29, buildOfflineSchema(), newVersion: 30);

    expect(await _hasTable(db, 'provisioning_drafts'), isTrue);
  });

  test('la table porte sa clé composite (école, utilisateur)', () async {
    await migrateOfflineDatabase(db, 29, buildOfflineSchema(), newVersion: 30);

    // Le cloisonnement n'est pas qu'une clause WHERE dans le DAO : la clé
    // primaire le grave dans le schéma, si bien que deux écoles ne peuvent
    // pas s'écraser mutuellement même sur un appel maladroit.
    await db.insert('provisioning_drafts', {
      'school_id': 'A',
      'user_id': 'u1',
      'payload': '{}',
      'step': 0,
      'max_step': 0,
      'updated_at': 0,
    });
    await db.insert('provisioning_drafts', {
      'school_id': 'B',
      'user_id': 'u1',
      'payload': '{}',
      'step': 0,
      'max_step': 0,
      'updated_at': 0,
    });

    expect(
      (await db.query('provisioning_drafts')).length,
      2,
      reason: 'deux écoles gardent chacune son brouillon',
    );
  });

  test('un brouillon existant survit à un rejeu de migration', () async {
    await migrateOfflineDatabase(db, 29, buildOfflineSchema(), newVersion: 30);
    await db.insert('provisioning_drafts', {
      'school_id': 'A',
      'user_id': 'u1',
      'payload': '{"cycles":[]}',
      'step': 3,
      'max_step': 4,
      'updated_at': 1,
    });

    await migrateOfflineDatabase(db, 29, buildOfflineSchema(), newVersion: 30);

    final rows = await db.query('provisioning_drafts');
    expect(rows.single['step'], 3);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v64 — le journal de classe : une table neuve, rien à recopier.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
  });
  tearDown(() => db.close());

  test('la table naît avec son index par cours et par jour', () async {
    await migrateTenantDatabase(db, 63, newVersion: 64);

    final columns = [
      for (final row in await db.rawQuery('PRAGMA table_info(journal_seance)'))
        row['name'] as String,
    ];
    expect(
      columns,
      containsAll([
        'cours_id',
        'date_seance',
        'time_slot_id',
        'chapitre_id',
        'objectif',
        'contenu',
        'client_updated_at',
        'sync_status',
      ]),
    );
    final indexes = await db.rawQuery('PRAGMA index_list(journal_seance)');
    expect(
      indexes.map((row) => row['name']),
      contains('idx_journal_seance_cours'),
    );
  });

  test('une base déjà en v64 ne la recrée pas', () async {
    await migrateTenantDatabase(db, 63, newVersion: 64);
    await db.insert('journal_seance', {
      'id': 'e',
      'cours_id': 'c',
      'date_seance': '2026-10-12',
      'time_slot_id': 's',
      'updated_at': 1,
    });

    await migrateTenantDatabase(db, 64, newVersion: 64);

    expect(await db.query('journal_seance'), hasLength(1));
  });
}

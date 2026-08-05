import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v21 → v22 : `content_sha256` devient nullable.
///
/// C'est la **seule reconstruction-avec-copie** de tout l'escalier de
/// migrations, et le dépôt n'a aucun `onDowngrade`. Une ligne perdue ici serait
/// un fichier chiffré devenu introuvable — donc une pièce qu'un guichet hors
/// ligne ne pourrait plus ressortir, alors qu'elle est sur son disque.
void main() {
  late Database db;

  /// Table dans sa forme v21 : `content_sha256 NOT NULL`, index LRU total.
  Future<void> createV21Table() async {
    await db.execute('''
      CREATE TABLE editique_cache_entries (
        id TEXT PRIMARY KEY,
        document_id TEXT,
        document_number TEXT,
        doc_type TEXT NOT NULL,
        student_id TEXT,
        academic_year_id TEXT,
        school_id TEXT NOT NULL,
        owner_uid TEXT NOT NULL DEFAULT '',
        size_bytes INTEGER NOT NULL,
        content_sha256 TEXT NOT NULL,
        emitted_at INTEGER,
        created_at INTEGER NOT NULL,
        last_accessed_at INTEGER NOT NULL,
        CHECK (
          COALESCE(NULLIF(document_id, ''), NULLIF(document_number, ''))
            IS NOT NULL
        ),
        CHECK (doc_type IN ('AI', 'NP', 'RC', 'BU'))
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_editique_cache_document '
      'ON editique_cache_entries(document_id)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_editique_cache_number '
      'ON editique_cache_entries(school_id, document_number)',
    );
    await db.execute(
      'CREATE INDEX idx_editique_cache_subject '
      'ON editique_cache_entries(school_id, student_id, academic_year_id, '
      'doc_type)',
    );
    await db.execute(
      'CREATE INDEX idx_editique_cache_lru '
      'ON editique_cache_entries(last_accessed_at)',
    );
  }

  Future<void> seed(String id, String documentId, {int size = 1024}) =>
      db.insert('editique_cache_entries', {
        'id': id,
        'document_id': documentId,
        'document_number': 'ETL-RC-$id',
        'doc_type': 'RC',
        'student_id': 's-1',
        'academic_year_id': 'y-1',
        'school_id': 'school-1',
        'owner_uid': 'u-1',
        'size_bytes': size,
        'content_sha256': 'a' * 64,
        'emitted_at': 500,
        'created_at': 1000,
        'last_accessed_at': 2000,
      });

  Future<void> migrate() =>
      migrateOfflineDatabase(db, 21, buildOfflineSchema());

  Future<bool> hashIsNullable() async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(editique_cache_entries)',
    );
    final hash = columns.firstWhere((c) => c['name'] == 'content_sha256');
    return (hash['notnull'] as int) == 0;
  }

  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await createV21Table();
  });

  tearDown(() async => db.close());

  test('relâche la contrainte sans perdre une seule ligne', () async {
    await seed('c-1', 'doc-1');
    await seed('c-2', 'doc-2', size: 4096);

    await migrate();

    expect(await hashIsNullable(), isTrue);
    final rows = await db.query('editique_cache_entries', orderBy: 'id');
    expect(rows.map((r) => r['id']), ['c-1', 'c-2']);
    // Chaque colonne recopiée, pas seulement la clé : une pièce dont on
    // perdrait l'empreinte serait déclarée corrompue à la relecture suivante,
    // et son fichier effacé.
    expect(rows.first['content_sha256'], 'a' * 64);
    expect(rows.first['document_number'], 'ETL-RC-c-1');
    expect(rows.first['school_id'], 'school-1');
    expect(rows.first['owner_uid'], 'u-1');
    expect(rows.last['size_bytes'], 4096);
    expect(rows.first['created_at'], 1000);
    expect(rows.first['last_accessed_at'], 2000);
  });

  test('accepte alors une ligne sans octets', () async {
    await migrate();

    await db.insert('editique_cache_entries', {
      'id': 'connue',
      'document_id': 'doc-9',
      'document_number': 'ETL-NP-9',
      'doc_type': 'NP',
      'school_id': 'school-1',
      'size_bytes': 4096,
      'created_at': 1000,
      'last_accessed_at': 1000,
    });

    final row = (await db.query(
      'editique_cache_entries',
      where: 'id = ?',
      whereArgs: ['connue'],
    )).single;
    expect(row['content_sha256'], isNull);
  });

  // Les contraintes du schéma canonique doivent survivre à la reconstruction :
  // ce sont elles qui interdisent une pièce horodatée et une pièce que rien
  // n'adresse.
  test('reconduit les contraintes de la table', () async {
    await migrate();

    await expectLater(
      db.insert('editique_cache_entries', {
        'id': 'quitus',
        'document_id': 'doc-qt',
        'doc_type': 'QT',
        'school_id': 'school-1',
        'size_bytes': 10,
        'created_at': 1,
        'last_accessed_at': 1,
      }),
      throwsA(anything),
    );
    await expectLater(
      db.insert('editique_cache_entries', {
        'id': 'anonyme',
        'doc_type': 'RC',
        'school_id': 'school-1',
        'size_bytes': 10,
        'created_at': 1,
        'last_accessed_at': 1,
      }),
      throwsA(anything),
    );
  });

  // L'index LRU devient PARTIEL en v22. `CREATE INDEX IF NOT EXISTS` ne
  // remplacerait pas une définition différente : c'est le DROP de l'ancienne
  // table qui libère le nom, et il faut le vérifier plutôt que l'espérer.
  test('recrée l index d éviction dans sa forme partielle', () async {
    await migrate();

    final sql =
        (await db.rawQuery(
              "SELECT sql FROM sqlite_master WHERE name = 'idx_editique_cache_lru'",
            )).single['sql']
            as String;
    expect(sql, contains('content_sha256 IS NOT NULL'));
  });

  test('reconduit l unicité de l identifiant serveur', () async {
    await seed('c-1', 'doc-1');
    await migrate();

    await expectLater(
      db.insert('editique_cache_entries', {
        'id': 'doublon',
        'document_id': 'doc-1',
        'document_number': 'ETL-RC-autre',
        'doc_type': 'RC',
        'school_id': 'school-1',
        'size_bytes': 10,
        'created_at': 1,
        'last_accessed_at': 1,
      }),
      throwsA(anything),
    );
  });

  // Aucun `onDowngrade` n'existe : une étape doit pouvoir être rejouée sans
  // dommage, par exemple après une migration interrompue puis reprise.
  test('se rejoue sans rien détruire', () async {
    await seed('c-1', 'doc-1');

    await migrate();
    await migrate();
    await migrate();

    expect(await hashIsNullable(), isTrue);
    expect(await db.query('editique_cache_entries'), hasLength(1));
  });

  test('ne fait rien sur une base qui n a pas la table', () async {
    await db.execute('DROP TABLE editique_cache_entries');

    await expectLater(migrate(), completes);
  });
}

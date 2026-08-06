import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v22 → v23 : `cancelled_at` et `cancellation_reason` sur
/// `editique_cache_entries`.
///
/// Deux `ALTER` sans backfill, ce qui rend l'étape banale — sauf sur un point
/// qui l'est beaucoup moins : **trois chemins mènent à la v23**, et ils
/// n'arrivent pas dans le même état.
///
/// - une base v22 a la table sans les colonnes → l'`ALTER` les pose ;
/// - une base v≤20 traverse d'abord le palier v21, qui crée la table depuis le
///   DDL **canonique** — donc avec les colonnes déjà présentes. Sans la garde
///   `_hasColumn`, l'`ALTER` lèverait `duplicate column name` et emporterait
///   toutes les migrations venues d'avant la v21 ;
/// - une base v21 traverse la reconstruction-avec-copie de la v22, qui recrée
///   la table depuis le même DDL canonique : mêmes colonnes, déjà là.
///
/// Chacun est éprouvé ici, parce qu'aucun ne se déduit des deux autres.
void main() {
  late Database db;

  /// Table dans sa forme **v22** : 13 colonnes, `content_sha256` nullable,
  /// index d'éviction partiel.
  Future<void> createV22Table() async {
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
        content_sha256 TEXT,
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
      'ON editique_cache_entries(last_accessed_at) '
      'WHERE content_sha256 IS NOT NULL',
    );
  }

  /// Table dans sa forme **v21** : `content_sha256 NOT NULL`, index LRU total.
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

  final sha = 'a' * 64;

  Future<void> seed(String id, {int size = 1024}) =>
      db.insert('editique_cache_entries', {
        'id': id,
        'document_id': 'doc-$id',
        'document_number': 'ETL-RC-$id',
        'doc_type': 'RC',
        'student_id': 's-1',
        'academic_year_id': 'y-1',
        'school_id': 'school-1',
        'owner_uid': 'u-1',
        'size_bytes': size,
        'content_sha256': sha,
        'emitted_at': 500,
        'created_at': 1000,
        'last_accessed_at': 2000,
      });

  Future<void> migrateFrom(int oldVersion) =>
      migrateOfflineDatabase(db, oldVersion, buildOfflineSchema());

  Future<Set<String>> columnNames() async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(editique_cache_entries)',
    );
    return {for (final column in columns) column['name'] as String};
  }

  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  });

  tearDown(() async => db.close());

  group('depuis la v22', () {
    setUp(createV22Table);

    test('pose les deux colonnes sans perdre une ligne', () async {
      await seed('c-1');
      await seed('c-2', size: 4096);

      await migrateFrom(22);

      expect(
        await columnNames(),
        containsAll(['cancelled_at', 'cancellation_reason']),
      );
      final rows = await db.query('editique_cache_entries', orderBy: 'id');
      expect(rows.map((r) => r['id']), ['c-1', 'c-2']);
      // Les octets survivent : une pièce détenue le reste, l'annulation est un
      // axe qui s'ajoute et n'efface rien.
      expect(rows.first['content_sha256'], 'a' * 64);
      expect(rows.last['size_bytes'], 4096);
    });

    // Aucun backfill n'est possible : une pièce déjà en cache n'a jamais connu
    // son annulation. NULL est donc le seul état honnête, et il se lit « on ne
    // sait pas encore », que le prochain delta lèvera.
    test('laisse les lignes existantes en vigueur', () async {
      await seed('c-1');

      await migrateFrom(22);

      final row = (await db.query('editique_cache_entries')).single;
      expect(row['cancelled_at'], isNull);
      expect(row['cancellation_reason'], isNull);
    });

    test('accepte alors une pièce annulée qui garde ses octets', () async {
      await migrateFrom(22);

      await db.insert('editique_cache_entries', {
        'id': 'annulee',
        'document_id': 'doc-9',
        'document_number': 'ETL-NP-9',
        'doc_type': 'NP',
        'school_id': 'school-1',
        'size_bytes': 4096,
        'content_sha256': 'b' * 64,
        'cancelled_at': 1786013000000,
        'cancellation_reason': 'Erreur de montant',
        'created_at': 1000,
        'last_accessed_at': 1000,
      });

      final row = (await db.query(
        'editique_cache_entries',
        where: 'id = ?',
        whereArgs: ['annulee'],
      )).single;
      expect(row['cancelled_at'], 1786013000000);
      expect(row['cancellation_reason'], 'Erreur de montant');
      // Les deux axes sont orthogonaux : annulée ET détenue est un état
      // parfaitement légitime, et c'est même le cas courant.
      expect(row['content_sha256'], 'b' * 64);
    });

    // Aucun `CHECK` ne lie les deux colonnes côté front, à la différence du
    // serveur : un delta décrit une donnée que le front ne contrôle pas, et
    // une contrainte ferait échouer son écriture au lieu de la recevoir.
    test('n impose aucun lien entre la date et le motif', () async {
      await migrateFrom(22);

      await expectLater(
        db.insert('editique_cache_entries', {
          'id': 'sans-motif',
          'document_id': 'doc-8',
          'doc_type': 'AI',
          'school_id': 'school-1',
          'size_bytes': 10,
          'cancelled_at': 1786013000000,
          'created_at': 1,
          'last_accessed_at': 1,
        }),
        completes,
      );
    });

    // Aucun `onDowngrade` n'existe : une étape doit pouvoir être rejouée après
    // une migration interrompue puis reprise.
    test('se rejoue sans rien détruire', () async {
      await seed('c-1');

      await migrateFrom(22);
      await migrateFrom(22);
      await migrateFrom(22);

      expect(
        await columnNames(),
        containsAll(['cancelled_at', 'cancellation_reason']),
      );
      expect(await db.query('editique_cache_entries'), hasLength(1));
    });

    test('ne fait rien sur une base qui n a pas la table', () async {
      await db.execute('DROP TABLE editique_cache_entries');

      await expectLater(migrateFrom(22), completes);
    });
  });

  // Le chemin qui fait tomber tout l'escalier si la garde `_hasColumn` manque :
  // le palier v21 crée la table depuis le DDL canonique, qui porte déjà les
  // colonnes de la v23.
  group('depuis la v20, où le palier v21 crée la table', () {
    test('ne relève pas duplicate column name', () async {
      await expectLater(migrateFrom(20), completes);

      expect(
        await columnNames(),
        containsAll(['cancelled_at', 'cancellation_reason']),
      );
    });

    test('se rejoue sans lever', () async {
      await migrateFrom(20);

      await expectLater(migrateFrom(20), completes);
    });
  });

  // Le chemin qui traverse la reconstruction-avec-copie de la v22 : la table
  // renaît du DDL canonique, donc déjà pourvue.
  group('depuis la v21, à travers la reconstruction de la v22', () {
    setUp(createV21Table);

    test('conduit à la forme v23 sans perdre la ligne', () async {
      await seed('c-1');

      await migrateFrom(21);

      expect(
        await columnNames(),
        containsAll(['cancelled_at', 'cancellation_reason']),
      );
      final row = (await db.query('editique_cache_entries')).single;
      expect(row['id'], 'c-1');
      // La reconstruction ne recopie que les 13 colonnes de la forme v21 — la
      // table source n'a pas les autres. Les colonnes neuves naissent donc
      // NULL, ce qui est l'état correct.
      expect(row['cancelled_at'], isNull);
      expect(row['content_sha256'], 'a' * 64);
    });

    test('se rejoue sans rien détruire', () async {
      await seed('c-1');

      await migrateFrom(21);
      await migrateFrom(21);

      expect(await db.query('editique_cache_entries'), hasLength(1));
    });
  });
}

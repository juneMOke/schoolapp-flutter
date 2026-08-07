import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Migration v20→v21 — index du cache de restitution éditique (ADR-012 D-2/D-7).
///
/// La table est neuve et ne porte **aucun octet** : ce que ces tests épinglent,
/// ce sont les invariants qui rendent cette absence tenable — types admis,
/// identité adressable, unicité — avant qu'un seul fichier n'existe.
bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
}

Future<List<Map<String, Object?>>> _tableInfo(Database db, String table) =>
    db.rawQuery('PRAGMA table_info($table)');

Map<String, Object?> _entry({
  String id = 'c-1',
  String? documentId = 'doc-1',
  String? documentNumber = 'ETL-RC-2526-000001',
  String docType = 'RC',
  String schoolId = 'school-1',
  int sizeBytes = 1024,
}) => {
  'id': id,
  'document_id': documentId,
  'document_number': documentNumber,
  'doc_type': docType,
  'student_id': 's-1',
  'academic_year_id': 'y-1',
  'school_id': schoolId,
  'owner_uid': 'u-1',
  'size_bytes': sizeBytes,
  'content_sha256': 'a' * 64,
  'emitted_at': 1000,
  'created_at': 2000,
  'last_accessed_at': 3000,
};

void main() {
  test('v20→v21 : la table de cache est créée', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    expect(await _tableInfo(db, 'editique_cache_entries'), isEmpty);

    await migrateOfflineDatabase(db, 20, buildOfflineSchema());

    final columns = (await _tableInfo(
      db,
      'editique_cache_entries',
    )).map((r) => r['name'] as String).toList();
    expect(
      columns,
      containsAll(<String>[
        'id',
        'document_id',
        'document_number',
        'doc_type',
        'student_id',
        'academic_year_id',
        'school_id',
        'owner_uid',
        'size_bytes',
        'content_sha256',
        'emitted_at',
        'created_at',
        'last_accessed_at',
      ]),
    );
  });

  // L'invariant central du lot : l'index ne stocke pas d'octets. Une colonne
  // BLOB rendue à cette table réintroduirait d'un coup le CursorWindow de 16 Ko
  // (relecture qui lève, invisible en CI) et la contention sur l'unique
  // connexion sqflite.
  test('v20→v21 : aucune colonne d\'octets', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);
    await migrateOfflineDatabase(db, 20, buildOfflineSchema());

    final types = (await _tableInfo(
      db,
      'editique_cache_entries',
    )).map((r) => (r['type'] as String? ?? '').toUpperCase()).toList();
    expect(types, isNotEmpty);
    expect(types.any((t) => t.contains('BLOB')), isFalse);
  });

  test('v20→v21 : rejouable sans effet de bord', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await migrateOfflineDatabase(db, 20, buildOfflineSchema());
    await db.insert('editique_cache_entries', _entry());
    await migrateOfflineDatabase(db, 20, buildOfflineSchema());

    final rows = await db.query('editique_cache_entries');
    expect(rows, hasLength(1));
    expect(rows.single['document_number'], 'ETL-RC-2526-000001');
  });

  group('contraintes de stockage', () {
    late Database db;

    setUp(() async {
      db = await _openLegacyDb();
      await migrateOfflineDatabase(db, 20, buildOfflineSchema());
    });

    tearDown(() async => db.close());

    // Un relevé ou un quitus n'est pas archivé par le serveur : la copie locale
    // en serait l'unique exemplaire, et l'éviction LRU la détruirait.
    test('un type non archivé est refusé', () async {
      await expectLater(
        db.insert('editique_cache_entries', _entry(docType: 'RL')),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert('editique_cache_entries', _entry(docType: 'QT')),
        throwsA(isA<DatabaseException>()),
      );
    });

    // Le bulletin s'archive côté serveur bien que le front ne sache pas
    // l'émettre : il descendra par le pull.
    test('le bulletin est admis', () async {
      await db.insert(
        'editique_cache_entries',
        _entry(docType: 'BU', documentId: 'doc-bu', documentNumber: null),
      );

      expect(await db.query('editique_cache_entries'), hasLength(1));
    });

    test('une entrée sans identifiant ni numéro est refusée', () async {
      await expectLater(
        db.insert(
          'editique_cache_entries',
          _entry(documentId: null, documentNumber: null),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    // Une chaîne vide n'adresse rien de plus que NULL — et c'est exactement ce
    // qu'un `Content-Disposition` mal formé produit.
    test('un identifiant vide ne vaut pas un identifiant', () async {
      await expectLater(
        db.insert(
          'editique_cache_entries',
          _entry(documentId: '', documentNumber: null),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert(
          'editique_cache_entries',
          _entry(documentId: null, documentNumber: ''),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('deux entrées sans numéro coexistent dans la même école', () async {
      await db.insert(
        'editique_cache_entries',
        _entry(id: 'c-1', documentId: 'doc-1', documentNumber: null),
      );
      await db.insert(
        'editique_cache_entries',
        _entry(id: 'c-2', documentId: 'doc-2', documentNumber: null),
      );

      expect(await db.query('editique_cache_entries'), hasLength(2));
    });

    test('deux entrées sans identifiant serveur coexistent', () async {
      await db.insert(
        'editique_cache_entries',
        _entry(id: 'c-1', documentId: null, documentNumber: 'ETL-AI-1'),
      );
      await db.insert(
        'editique_cache_entries',
        _entry(id: 'c-2', documentId: null, documentNumber: 'ETL-AI-2'),
      );

      expect(await db.query('editique_cache_entries'), hasLength(2));
    });

    test(
      'le même identifiant serveur ne peut pas être indexé deux fois',
      () async {
        await db.insert('editique_cache_entries', _entry(id: 'c-1'));

        await expectLater(
          db.insert(
            'editique_cache_entries',
            _entry(id: 'c-2', documentNumber: 'ETL-RC-2526-000002'),
          ),
          throwsA(isA<DatabaseException>()),
        );
      },
    );

    test('le numéro est unique PAR école, pas globalement', () async {
      await db.insert(
        'editique_cache_entries',
        _entry(id: 'c-1', documentId: 'doc-1'),
      );
      // Même numéro, autre école : légitime, les séquences sont par
      // établissement.
      await db.insert(
        'editique_cache_entries',
        _entry(id: 'c-2', documentId: 'doc-2', schoolId: 'school-2'),
      );

      expect(await db.query('editique_cache_entries'), hasLength(2));

      await expectLater(
        db.insert(
          'editique_cache_entries',
          _entry(id: 'c-3', documentId: 'doc-3'),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}

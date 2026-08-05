import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';

import '../../../offline_full_db.dart';
import 'editique_cache_fixtures.dart';

/// Vie normale de l'index du cache éditique — exercée **sans un seul octet** :
/// c'est tout l'intérêt de poser l'index avant le magasin de fichiers.
void main() {
  late Database db;
  late EditiqueCacheDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EditiqueCacheDao(db);
  });

  tearDown(() async => db.close());

  group('lecture', () {
    test('une pièce absente du cache rend null', () async {
      expect(await dao.findByDocumentId('doc-inconnu'), isNull);
      expect(
        await dao.findByDocumentNumber(
          schoolId: 'school-1',
          documentNumber: 'ETL-RC-0',
        ),
        isNull,
      );
    });

    test('retrouve une entrée par identifiant serveur et par numéro', () async {
      await dao.upsert(cacheEntry());

      expect((await dao.findByDocumentId('doc-1'))?.id, 'c-1');
      expect(
        (await dao.findByDocumentNumber(
          schoolId: 'school-1',
          documentNumber: 'ETL-RC-2526-000001',
        ))?.id,
        'c-1',
      );
    });

    // Le numéro n'est unique que par école : le chercher sans son école
    // rendrait la pièce d'un autre établissement.
    test('la recherche par numéro est scopée par école', () async {
      await dao.upsert(cacheEntry(id: 'c-1', documentId: 'doc-1'));
      await dao.upsert(
        cacheEntry(id: 'c-2', documentId: 'doc-2', schoolId: 'school-2'),
      );

      expect(
        (await dao.findByDocumentNumber(
          schoolId: 'school-2',
          documentNumber: 'ETL-RC-2526-000001',
        ))?.id,
        'c-2',
      );
    });

    test('la liste d\'un élève est scopée par école', () async {
      await dao.upsert(cacheEntry(id: 'c-1', documentId: 'doc-1'));
      await dao.upsert(
        cacheEntry(id: 'c-2', documentId: 'doc-2', schoolId: 'school-2'),
      );

      final rows = await dao.listForStudent(
        schoolId: 'school-1',
        studentId: 's-1',
      );
      expect(rows.map((e) => e.id), ['c-1']);
    });

    test('l\'année est facultative dans la liste d\'un élève', () async {
      await dao.upsert(
        cacheEntry(id: 'c-1', documentId: 'doc-1', academicYearId: 'y-1'),
      );
      await dao.upsert(
        cacheEntry(
          id: 'c-2',
          documentId: 'doc-2',
          documentNumber: 'ETL-RC-2526-000002',
          academicYearId: 'y-2',
        ),
      );

      expect(
        await dao.listForStudent(schoolId: 'school-1', studentId: 's-1'),
        hasLength(2),
      );
      expect(
        (await dao.listForStudent(
          schoolId: 'school-1',
          studentId: 's-1',
          academicYearId: 'y-2',
        )).map((e) => e.id),
        ['c-2'],
      );
    });

    // Un bulletin de juin descendu par la synchro de septembre n'est pas la
    // pièce la plus récente de l'élève : la liste s'ordonne sur l'émission, pas
    // sur la mise en cache.
    test('la liste s\'ordonne sur la date d\'émission', () async {
      await dao.upsert(
        cacheEntry(
          id: 'ancien',
          documentId: 'doc-ancien',
          emittedAt: 100,
          createdAt: 9000,
        ),
      );
      await dao.upsert(
        cacheEntry(
          id: 'recent',
          documentId: 'doc-recent',
          documentNumber: 'ETL-RC-2526-000002',
          emittedAt: 900,
          createdAt: 1,
        ),
      );

      final rows = await dao.listForStudent(
        schoolId: 'school-1',
        studentId: 's-1',
      );
      expect(rows.map((e) => e.id), ['recent', 'ancien']);
    });

    test('une émission inconnue passe en dernier', () async {
      await dao.upsert(
        cacheEntry(id: 'sans-date', documentId: 'doc-1', emittedAt: null),
      );
      await dao.upsert(
        cacheEntry(
          id: 'datee',
          documentId: 'doc-2',
          documentNumber: 'ETL-RC-2526-000002',
          emittedAt: 5,
        ),
      );

      final rows = await dao.listForStudent(
        schoolId: 'school-1',
        studentId: 's-1',
      );
      expect(rows.map((e) => e.id), ['datee', 'sans-date']);
    });
  });

  group('écriture', () {
    // `replace` supprimerait puis réinsérerait la ligne : la clé locale
    // changerait, donc le nom du fichier chiffré, donc le fichier deviendrait
    // orphelin — invisible à la comptabilité de budget.
    test(
      'un ré-upsert conserve la clé locale et la date de mise en cache',
      () async {
        await dao.upsert(
          cacheEntry(id: 'c-1', createdAt: 2000, sizeBytes: 1024),
        );

        await dao.upsert(
          cacheEntry(id: 'autre-cle', createdAt: 8000, sizeBytes: 2048),
        );

        final rows = await db.query('editique_cache_entries');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'c-1');
        expect(rows.single['created_at'], 2000);
        expect(rows.single['size_bytes'], 2048);
      },
    );

    // Le chemin ouvert par le lot B2 : une entrée indexée par numéro seul se
    // voit compléter son identifiant le jour où le serveur l'expose.
    test(
      'une entrée indexée par numéro reçoit son identifiant plus tard',
      () async {
        await dao.upsert(cacheEntry(id: 'c-1', documentId: null));

        await dao.upsert(cacheEntry(id: 'ignoree', documentId: 'doc-1'));

        final rows = await db.query('editique_cache_entries');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'c-1');
        expect(rows.single['document_id'], 'doc-1');
      },
    );

    // Une source qui ne connaît pas l'identifiant ne doit pas effacer celui
    // qu'une autre a déjà posé.
    test('un identifiant déjà connu n\'est pas effacé par un null', () async {
      await dao.upsert(
        cacheEntry(id: 'c-1', documentId: 'doc-1', emittedAt: 77),
      );

      await dao.upsert(
        cacheEntry(id: 'c-1', documentId: null, emittedAt: null),
      );

      final stored = await dao.findByDocumentId('doc-1');
      expect(stored?.documentId, 'doc-1');
      expect(stored?.emittedAt, 77);
    });

    // Un relevé ou un quitus n'est pas archivé par le serveur : la copie locale
    // en serait l'unique exemplaire, et l'éviction LRU la détruirait.
    test('un type non archivé est refusé', () async {
      await expectLater(
        dao.upsert(cacheEntry(docType: 'RL')),
        throwsA(isA<ArgumentError>()),
      );
      expect(await dao.count(), 0);
    });

    test('une entrée sans identifiant ni numéro est refusée', () async {
      await expectLater(
        dao.upsert(cacheEntry(documentId: null, documentNumber: null)),
        throwsA(isA<ArgumentError>()),
      );
      expect(await dao.count(), 0);
    });

    // « Inconnu » doit s'écrire NULL : c'est la seule valeur que les index
    // uniques considèrent comme distincte d'elle-même. Stockées telles quelles,
    // deux chaînes vides feraient entrer en collision deux pièces dont on
    // ignore simplement l'identifiant.
    test('un identifiant vide est stocké comme inconnu', () async {
      await dao.upsert(cacheEntry(id: 'c-1', documentId: ''));
      await dao.upsert(
        cacheEntry(id: 'c-2', documentId: '', documentNumber: 'ETL-RC-2'),
      );

      final rows = await db.query('editique_cache_entries', orderBy: 'id ASC');
      expect(rows, hasLength(2));
      expect(rows.first['document_id'], isNull);
    });

    // La garde Dart tolère la casse, la contrainte SQL non : sans
    // normalisation à l'écriture, un type minuscule traverserait la première
    // pour se faire refuser par la seconde.
    test('le type est stocké dans sa forme canonique', () async {
      await dao.upsert(cacheEntry(docType: 'rc'));

      expect(
        (await db.query('editique_cache_entries')).single['doc_type'],
        'RC',
      );
    });

    test('touch enregistre l\'accès', () async {
      await dao.upsert(cacheEntry(id: 'c-1', lastAccessedAt: 10));

      await dao.touch(id: 'c-1', nowMs: 30);

      expect((await dao.findByDocumentId('doc-1'))?.lastAccessedAt, 30);
    });
  });

  group('mesure', () {
    setUp(() async {
      await dao.upsert(
        cacheEntry(
          id: 'c-1',
          documentId: 'doc-1',
          sizeBytes: 100,
          academicYearId: 'y-1',
        ),
      );
      await dao.upsert(
        cacheEntry(
          id: 'c-2',
          documentId: 'doc-2',
          documentNumber: 'ETL-RC-2',
          sizeBytes: 200,
          academicYearId: 'y-2',
        ),
      );
      await dao.upsert(
        cacheEntry(
          id: 'c-3',
          documentId: 'doc-3',
          documentNumber: 'ETL-RC-3',
          sizeBytes: 400,
          schoolId: 'school-2',
        ),
      );
    });

    // Le budget est une propriété du disque de la tablette : il ne se divise
    // pas par école, il se partage.
    test('le poids total couvre tout l\'appareil', () async {
      expect(await dao.totalSizeBytes(), 700);
    });

    test('le poids se mesure aussi par école', () async {
      expect(await dao.totalSizeBytes(schoolId: 'school-1'), 300);
    });

    test('un cache vide pèse zéro, pas null', () async {
      await db.delete('editique_cache_entries');

      expect(await dao.totalSizeBytes(), 0);
      expect(await dao.count(), 0);
    });

    test('le poids se ventile par année', () async {
      expect(await dao.sizeBytesByAcademicYear('school-1'), {
        'y-1': 100,
        'y-2': 200,
      });
    });

    test('les pièces sans année sont regroupées, pas perdues', () async {
      await dao.upsert(
        cacheEntry(
          id: 'c-4',
          documentId: 'doc-4',
          documentNumber: 'ETL-RC-4',
          sizeBytes: 50,
          academicYearId: null,
        ),
      );

      expect(await dao.sizeBytesByAcademicYear('school-1'), {
        '': 50,
        'y-1': 100,
        'y-2': 200,
      });
    });
  });

  // La question que le magasin d'octets doit poser AVANT d'écrire un fichier :
  // c'est la clé locale de la ligne existante qui le nomme, et `upsert` la
  // conserve. Écrire sous une clé fraîche laisserait un fichier orphelin.
  group('identité d une entrée', () {
    test('reconnaît une entrée par son identifiant serveur', () async {
      await dao.upsert(cacheEntry());

      final found = await dao.findIdentity(
        cacheEntry(id: 'peu-importe', documentNumber: 'ETL-RC-inconnu'),
      );

      expect(found?.id, 'c-1');
    });

    test('reconnaît une entrée par son numéro, dans son école', () async {
      await dao.upsert(cacheEntry());

      final trouvee = await dao.findIdentity(
        cacheEntry(id: 'peu-importe', documentId: null),
      );
      final ailleurs = await dao.findIdentity(
        cacheEntry(id: 'peu-importe', documentId: null, schoolId: 'school-2'),
      );

      expect(trouvee?.id, 'c-1');
      expect(ailleurs, isNull);
    });

    test('une pièce jamais vue n a pas d identité locale', () async {
      expect(
        await dao.findIdentity(
          cacheEntry(documentId: 'doc-9', documentNumber: 'ETL-RC-9'),
        ),
        isNull,
      );
    });
  });
}

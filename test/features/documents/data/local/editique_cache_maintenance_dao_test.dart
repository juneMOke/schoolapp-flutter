import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_maintenance_dao.dart';

import '../../../offline_full_db.dart';
import 'editique_cache_fixtures.dart';

/// Balayage LRU et effacement du cache éditique — éprouvés **à vide**, avant
/// qu'un seul fichier n'existe (lot L3.2).
void main() {
  late Database db;
  late EditiqueCacheDao dao;
  late EditiqueCacheMaintenanceDao maintenance;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EditiqueCacheDao(db);
    maintenance = EditiqueCacheMaintenanceDao(db);
  });

  tearDown(() async => db.close());

  group('classement LRU', () {
    test('un cache vide ne propose aucune victime', () async {
      expect(await maintenance.footprintsByLeastRecentlyUsed(), isEmpty);
    });

    test('un accès déplace l\'entrée dans le classement', () async {
      await dao.upsert(
        cacheEntry(id: 'c-1', documentId: 'doc-1', lastAccessedAt: 10),
      );
      await dao.upsert(
        cacheEntry(
          id: 'c-2',
          documentId: 'doc-2',
          documentNumber: 'ETL-RC-2',
          lastAccessedAt: 20,
        ),
      );

      expect(
        (await maintenance.footprintsByLeastRecentlyUsed()).map((f) => f.id),
        ['c-1', 'c-2'],
      );

      // Sans ce déplacement, le cache évincerait par ancienneté de mise en
      // cache : la pièce ressortie tous les jours partirait la première.
      await dao.touch(id: 'c-1', nowMs: 30);

      expect(
        (await maintenance.footprintsByLeastRecentlyUsed()).map((f) => f.id),
        ['c-2', 'c-1'],
      );
    });

    // Sans départage, deux balayages successifs pourraient évincer des entrées
    // différentes pour un même état de cache.
    test('les égalités d\'accès se départagent de façon stable', () async {
      for (final id in ['c-3', 'c-1', 'c-2']) {
        await dao.upsert(
          cacheEntry(
            id: id,
            documentId: 'doc-$id',
            documentNumber: 'ETL-RC-$id',
            lastAccessedAt: 10,
            createdAt: 5,
          ),
        );
      }

      expect(
        (await maintenance.footprintsByLeastRecentlyUsed()).map((f) => f.id),
        ['c-1', 'c-2', 'c-3'],
      );
    });

    test('l\'empreinte porte la taille, telle que mesurée', () async {
      await dao.upsert(cacheEntry(id: 'c-1', sizeBytes: 4096));

      expect(
        (await maintenance.footprintsByLeastRecentlyUsed()).single.sizeBytes,
        4096,
      );
    });
  });

  group('suppression ciblée', () {
    test('retire exactement les lignes désignées', () async {
      await dao.upsert(cacheEntry(id: 'c-1', documentId: 'doc-1'));
      await dao.upsert(
        cacheEntry(id: 'c-2', documentId: 'doc-2', documentNumber: 'ETL-RC-2'),
      );

      expect(await maintenance.deleteEntries(['c-1']), 1);
      expect(
        (await maintenance.footprintsByLeastRecentlyUsed()).map((f) => f.id),
        ['c-2'],
      );
    });

    test('une liste vide ne touche à rien', () async {
      expect(await maintenance.deleteEntries(const []), 0);
      expect(await maintenance.deleteEntries(const ['']), 0);
    });

    // Le nombre de paramètres liés est plafonné par SQLite : un balayage large
    // doit être découpé, sinon il lève au pire moment.
    test('supporte plus de victimes qu\'un IN ne tient', () async {
      final ids = <String>[];
      for (var i = 0; i < 450; i++) {
        final id = 'c-$i';
        ids.add(id);
        await dao.upsert(
          cacheEntry(id: id, documentId: 'doc-$i', documentNumber: 'ETL-RC-$i'),
        );
      }

      expect(await maintenance.deleteEntries(ids), 450);
      expect(await dao.count(), 0);
    });
  });

  group('effacement de D-7', () {
    test('la réaffectation désigne les entrées étrangères', () async {
      await dao.upsert(cacheEntry(id: 'c-1', documentId: 'doc-1'));
      await dao.upsert(
        cacheEntry(
          id: 'c-2',
          documentId: 'doc-2',
          documentNumber: 'ETL-RC-2',
          schoolId: 'school-2',
        ),
      );

      final foreign = await maintenance.foreignSchoolEntries('school-1');

      expect(foreign.map((e) => e.id), ['c-2']);
      // Désigner n'efface pas : les fichiers partent d'abord, les lignes
      // ensuite, sinon un arrêt entre les deux laisse des pièces d'un autre
      // établissement que plus rien ne désigne.
      expect(await dao.count(), 2);
    });

    test(
      'la réaffectation ne désigne rien quand tout appartient à l\'école',
      () async {
        await dao.upsert(cacheEntry(id: 'c-1', documentId: 'doc-1'));

        expect(await maintenance.foreignSchoolEntries('school-1'), isEmpty);
        expect(await dao.count(), 1);
      },
    );

    // `CurrentUserContext` rend null avant l'authentification : interpréter
    // « aucune école » comme « toutes sont étrangères » viderait le cache à
    // chaque démarrage à froid.
    test('la réaffectation refuse une école inconnue', () async {
      await dao.upsert(cacheEntry(id: 'c-1', documentId: 'doc-1'));

      await expectLater(
        maintenance.foreignSchoolEntries(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(await dao.count(), 1);
    });

    test('purgeAll vide le cache et rend tout ce qu\'il a retiré', () async {
      await dao.upsert(cacheEntry(id: 'c-1', documentId: 'doc-1'));
      await dao.upsert(
        cacheEntry(id: 'c-2', documentId: 'doc-2', documentNumber: 'ETL-RC-2'),
      );

      final removed = await maintenance.purgeAll();

      expect(removed.map((e) => e.id), containsAll(['c-1', 'c-2']));
      expect(await dao.count(), 0);
    });

    test('purgeAll sur un cache vide ne rend rien', () async {
      expect(await maintenance.purgeAll(), isEmpty);
    });
  });
}

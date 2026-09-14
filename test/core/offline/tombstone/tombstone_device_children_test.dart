import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../offline_full_test_db.dart';

Future<int> _count(Database db, String table) async =>
    ((await db.rawQuery('SELECT COUNT(*) AS n FROM $table')).first['n']
        as int?) ??
    0;

/// Le retrait d'une pièce scellée purge l'index éditique là où il vit : dans
/// la base de l'APPAREIL (MULTI_ECOLE_PLAN.md §10.2), pas dans celle de
/// l'école.
void main() {
  late Database school;
  late Database device;
  late TombstoneDao dao;

  setUp(() async {
    school = await openFullOfflineDb();
    device = await openFullOfflineDb();
    dao = TombstoneDao(school, SyncMetaDao(school), deviceDb: device);
  });

  tearDown(() async {
    await school.close();
    await device.close();
  });

  Map<String, Object?> cacheEntry(String documentId) => {
    'id': 'cache-$documentId',
    'document_id': documentId,
    'doc_type': 'RC',
    'school_id': 'school-a',
    'size_bytes': 10,
    'created_at': 1,
    'last_accessed_at': 1,
  };

  Future<void> givenDocument(String id) async {
    await school.insert('generated_documents', {
      'id': id,
      'doc_domain': 'FINANCE',
      'doc_type': 'RC',
      'number': 'RC-$id',
    });
    await device.insert('editique_cache_entries', cacheEntry(id));
  }

  const withdrawn = TombstoneDto(
    resource: 'editique_documents',
    entityId: 'doc-1',
    reason: TombstoneReason.deleted,
  );

  test('une pièce retirée quitte l index de l appareil', () async {
    await givenDocument('doc-1');

    final result = await dao.apply(const [withdrawn]);

    expect(result.removed, 1);
    expect(await _count(school, 'generated_documents'), 0);
    expect(await _count(device, 'editique_cache_entries'), 0);
  });

  // La contre-épreuve du routage : la base de test porte le schéma complet,
  // donc AUSSI une table d'index côté école. C'est celle de l'appareil qui doit
  // être purgée — une purge routée vers l'école laisserait la pièce servie.
  test('c est l index de l APPAREIL qui est purgé, pas un homonyme côté '
      'école', () async {
    await givenDocument('doc-1');
    await school.insert('editique_cache_entries', cacheEntry('doc-1'));

    await dao.apply(const [withdrawn]);

    expect(await _count(device, 'editique_cache_entries'), 0);
    expect(await _count(school, 'editique_cache_entries'), 1);
  });

  test(
    'un retrait qui ne vise aucune pièce locale ne touche pas l index',
    () async {
      await givenDocument('doc-1');

      await dao.apply(const [
        TombstoneDto(
          resource: 'editique_documents',
          entityId: 'doc-inconnue',
          reason: TombstoneReason.deleted,
        ),
      ]);

      expect(await _count(device, 'editique_cache_entries'), 1);
    },
  );

  test('sans base d appareil (base unique), l index se purge dans la base '
      'de l école', () async {
    final single = TombstoneDao(school, SyncMetaDao(school));
    await school.insert('generated_documents', {
      'id': 'doc-1',
      'doc_domain': 'FINANCE',
      'doc_type': 'RC',
      'number': 'RC-1',
    });
    await school.insert('editique_cache_entries', cacheEntry('doc-1'));

    await single.apply(const [withdrawn]);

    expect(await _count(school, 'editique_cache_entries'), 0);
  });
}

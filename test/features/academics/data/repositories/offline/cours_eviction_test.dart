import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

/// Le contrat entre modules : un cours réaffecté quitte la tablette en un
/// seul endroit, modules enregistrés et curseurs de leurs flux compris.
void main() {
  late Database db;
  late SyncMetaDao syncMeta;
  late AcademicsRefLocalDataSource refLocal;
  late CoursEviction eviction;

  setUp(() async {
    db = await openFullOfflineDb();
    syncMeta = SyncMetaDao(db);
    refLocal = AcademicsRefLocalDataSource(db);
    eviction = CoursEviction(
      refLocalDataSource: refLocal,
      localDataSource: AcademicsLocalDataSource(db),
      syncMetaDao: syncMeta,
      cursorPrefixes: const {kAcademicsEvaluationsResourcePrefix},
    );
    await db.insert('ref_cours', {
      'id': 'co-lost',
      'classroom_id': 'class-1',
      'ligne_bareme_id': 'lb-1',
      'synced_at': 1,
    });
  });
  tearDown(() => db.close());

  test(
    'le module enregistré évince, et les curseurs de son flux partent',
    () async {
      final evicted = <String>[];
      eviction.register(
        cursorPrefix: kAcademicsChapitresResourcePrefix,
        evict: (coursId) async => evicted.add(coursId),
      );
      for (final key in [
        '$kAcademicsChapitresResourcePrefix:co-lost',
        '${kAcademicsChapitresResourcePrefix}_bootstrap:co-lost',
        '$kAcademicsEvaluationsResourcePrefix:co-lost',
      ]) {
        await syncMeta.setCursor(key, cursor: 'c', syncedAt: 1);
      }

      await eviction.evict('co-lost');

      expect(evicted, ['co-lost']);
      expect(await refLocal.getCours('co-lost'), isNull);
      expect(
        await syncMeta.getCursor('$kAcademicsChapitresResourcePrefix:co-lost'),
        isNull,
      );
      expect(
        await syncMeta.getCursor(
          '${kAcademicsChapitresResourcePrefix}_bootstrap:co-lost',
        ),
        isNull,
      );
      expect(
        await syncMeta.getCursor(
          '$kAcademicsEvaluationsResourcePrefix:co-lost',
        ),
        isNull,
      );
    },
  );
}

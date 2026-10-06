import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _MockStore extends Mock implements EncryptedBlobStore {}

/// Un magasin par école : le ménage d'une école ne touche jamais les
/// documents en attente d'une autre école du poste.
void main() {
  late Database db;
  late Map<String?, _MockStore> stores;
  String? school = 'school-a';

  setUp(() async {
    db = await openFullOfflineDb();
    stores = {};
    school = 'school-a';
  });
  tearDown(() => db.close());

  ProgrammeBlobs blobs() => ProgrammeBlobs(
    storeFor: (schoolId) => stores.putIfAbsent(schoolId, () {
      final store = _MockStore();
      when(
        () => store.reclaimOrphans(indexedIds: any(named: 'indexedIds')),
      ).thenAnswer((_) async => 0);
      when(() => store.read(any())).thenAnswer((_) async => const BlobGone());
      return store;
    }),
    schoolId: () => school,
    db: db,
  );

  test('le ménage ne passe que dans le magasin de l\'école ouverte', () async {
    await db.insert('chapitre_ressource', {
      'id': 'r-1',
      'chapitre_id': 'ch-1',
      'cours_id': 'c-1',
      'type': 'document',
      'nom': 'Fiche',
      'updated_at': 1,
    });
    final programme = blobs();
    await programme.read('r-0');
    school = 'school-b';
    await programme.reclaimOrphans();

    expect(stores.keys, containsAll(['school-a', 'school-b']));
    verify(
      () => stores['school-b']!.reclaimOrphans(indexedIds: {'r-1'}),
    ).called(1);
    verifyNever(
      () => stores['school-a']!.reclaimOrphans(
        indexedIds: any(named: 'indexedIds'),
      ),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_dao.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

/// Les lectures du programme : ordre, fiche décodée, lignes masquées.
void main() {
  late Database db;
  late ChapitreDao dao;

  Future<void> seedChapitre(
    String id, {
    required int ordre,
    String coursId = 'c-1',
    String? deletedAt,
    int serverKnown = 1,
    String? serverUpdatedAt = '2026-10-01T08:00:00.000Z',
  }) => db.insert('chapitre', {
    'id': id,
    'cours_id': coursId,
    'ordre': ordre,
    'titre': 'Chapitre $id',
    'statut': 'EN_COURS',
    'objectifs_json':
        '[{"id":"o-1","texte":"Lire","atteint":true},{"id":"o-2","texte":"Écrire","atteint":false},{"texte":"sans id"}]',
    'strategies_json': '["Travail en groupe"]',
    'blocs_json': '[{"id":"b-1","type":"liste","texte":"","items":["a","b"]}]',
    'server_known': serverKnown,
    'server_updated_at': serverUpdatedAt,
    'sync_status': 'SYNCED',
    'deleted_at': deletedAt,
    'updated_at': 1,
  });

  Future<void> seedNote(String id, String chapitreId, String ecriteLe) =>
      db.insert('chapitre_note', {
        'id': id,
        'chapitre_id': chapitreId,
        'cours_id': 'c-1',
        'texte': 'Séance $id',
        'ecrite_le': ecriteLe,
        'updated_at': 1,
      });

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ChapitreDao(db);
  });
  tearDown(() => db.close());

  test('rend les chapitres dans l\'ordre, sans les supprimés', () async {
    await seedChapitre('b', ordre: 1);
    await seedChapitre('a', ordre: 0);
    await seedChapitre('x', ordre: 2, deletedAt: '2026-10-02T08:00:00.000Z');
    await seedChapitre('z', ordre: 0, coursId: 'c-2');

    final chapitres = await dao.chapitresOfCours('c-1');
    expect(chapitres.map((c) => c.id), ['a', 'b']);
    expect(await dao.find('x'), isNull);
  });

  test('décode la fiche et écarte un élément illisible', () async {
    await seedChapitre('a', ordre: 0);

    final chapitre = (await dao.find('a'))!;
    expect(chapitre.statut, ChapitreStatut.enCours);
    expect(chapitre.objectifs.map((o) => o.id), ['o-1', 'o-2']);
    expect(chapitre.objectifsAtteints, 1);
    expect(chapitre.strategies, ['Travail en groupe']);
    expect(chapitre.blocs.single.type, ChapitreBlocType.liste);
    expect(chapitre.blocs.single.items, ['a', 'b']);
    expect(chapitre.awaitingDownload, isFalse);
  });

  test('une ébauche jamais descendue attend son téléchargement', () async {
    await seedChapitre('a', ordre: 0, serverUpdatedAt: null);
    expect((await dao.find('a'))!.awaitingDownload, isTrue);
  });

  test('notes : la plus récente en tête, comptées par chapitre', () async {
    await seedChapitre('a', ordre: 0);
    await seedNote('n-1', 'a', '2026-10-01T08:00:00.000Z');
    await seedNote('n-2', 'a', '2026-10-03T08:00:00.000Z');

    expect((await dao.notesOf('a')).map((n) => n.id), ['n-2', 'n-1']);
    expect(await dao.notesCountByChapitre('c-1'), {'a': 2});
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../programme_test_fakes.dart';

/// Un geste local = la ligne et son entrée d'outbox, ensemble.
void main() {
  late Database db;
  late FakeProgrammeBlobs blobs;
  late ChapitreWriteDao dao;

  Chapitre chapitre(String id, {String titre = 'Fractions', int at = 1}) =>
      Chapitre(
        id: id,
        coursId: 'c-1',
        ordre: 0,
        titre: titre,
        clientUpdatedAt: DateTime.utc(2026, 10, at),
      );

  Future<Map<String, Object?>?> row(String id) async => (await db.query(
    'chapitre',
    where: 'id = ?',
    whereArgs: [id],
  )).firstOrNull;

  setUp(() async {
    db = await openFullOfflineDb();
    blobs = FakeProgrammeBlobs();
    dao = ChapitreWriteDao(db: db, blobs: blobs);
  });
  tearDown(() => db.close());

  test('un chapitre neuf se range en fin, inconnu du serveur', () async {
    await dao.saveChapitre(chapitre('a'), schoolId: 's-1', nowMs: 1);
    await dao.saveChapitre(chapitre('b'), schoolId: 's-1', nowMs: 2);

    expect((await row('b'))!['ordre'], 1);
    expect((await row('b'))!['server_known'], 0);
    final entry = (await outboxById(db))[ProgrammeOutbox.chapitreEntry('b')]!;
    expect(entry.schoolId, 's-1');
    expect(jsonDecode(entry.payload)['op'], 'save');
  });

  test('un second enregistrement remplace l\'entrée en attente', () async {
    await dao.saveChapitre(chapitre('a'), schoolId: null, nowMs: 1);
    await dao.saveChapitre(
      chapitre('a', titre: 'Décimaux', at: 2),
      schoolId: null,
      nowMs: 2,
    );

    final entries = await outboxById(db);
    expect(entries, hasLength(1));
    final fiche = jsonDecode(entries.values.single.payload)['fiche'] as Map;
    expect(fiche['titre'], 'Décimaux');
    expect((await row('a'))!['ordre'], 0);
  });

  test('supprimer un chapitre jamais envoyé le retire des évaluations en '
      'attente, ligne et payload', () async {
    await dao.saveChapitre(chapitre('a'), schoolId: null, nowMs: 1);
    await db.insert('evaluation', {
      'id': 'ev-1',
      'cours_id': 'c-1',
      'type': 'INTERRO',
      'eval_date': 0,
      'max_points': 20.0,
      'poids': 1,
      'updated_at': 1,
      'sync_status': 'PENDING_SYNC',
      'chapitre_ids_json': '["a","z"]',
    });
    await OutboxDao(db).enqueue(
      OutboxEntry(
        id: EvaluationOfflineRepositoryImpl.aggregateOutboxId('ev-1'),
        aggregateType: kEvaluationAggregateType,
        aggregateId: 'ev-1',
        operation: OutboxOperation.create,
        payload: EvaluationPushRequestModel(
          coursId: 'c-1',
          evaluation: EvaluationInputModel(
            id: 'ev-1',
            coursId: 'c-1',
            type: 'INTERRO',
            date: DateTime.utc(2026, 10, 1),
            maxPoints: 20,
            poids: 1,
            chapitreIds: const ['a', 'z'],
          ),
        ).toJsonString(),
        createdAt: 1,
      ),
    );

    await dao.deleteChapitre('a', schoolId: null, nowMs: 3);

    expect(await row('a'), isNull);
    final entries = await outboxById(db);
    expect(
      entries[ProgrammeOutbox.chapitreEntry('a')]!.status,
      OutboxStatus.acked,
    );
    final eval = (await db.query('evaluation')).single;
    expect(eval['chapitre_ids_json'], '["z"]');
    final evalEntry =
        entries[EvaluationOfflineRepositoryImpl.aggregateOutboxId('ev-1')]!;
    expect(
      EvaluationPushRequestModel.fromJsonString(
        evalEntry.payload,
      ).evaluation.chapitreIds,
      ['z'],
    );
    expect(blobs.reclaims, 1);
  });

  test('supprimer un chapitre connu le masque et remplace sa fiche en '
      'attente ; ses notes en attente sont abandonnées', () async {
    await dao.saveChapitre(chapitre('a'), schoolId: null, nowMs: 1);
    await db.update('chapitre', {'server_known': 1});
    await OutboxDao(db).enqueue(
      OutboxEntry(
        id: ProgrammeOutbox.noteEntry('n-1'),
        aggregateType: ProgrammeOutbox.noteType,
        aggregateId: 'a',
        operation: OutboxOperation.upsert,
        payload: '{}',
        createdAt: 2,
      ),
    );

    await dao.deleteChapitre('a', schoolId: null, nowMs: 3);

    expect((await row('a'))!['deleted_at'], isNotNull);
    final entries = await outboxById(db);
    final chapitreEntry = entries[ProgrammeOutbox.chapitreEntry('a')]!;
    expect(chapitreEntry.status, OutboxStatus.pending);
    expect(jsonDecode(chapitreEntry.payload)['op'], 'delete');
    expect(
      entries[ProgrammeOutbox.noteEntry('n-1')]!.status,
      OutboxStatus.acked,
    );
  });

  test('réordonner range les rangs et met la liste en file', () async {
    await dao.saveChapitre(chapitre('a'), schoolId: null, nowMs: 1);
    await dao.saveChapitre(chapitre('b'), schoolId: null, nowMs: 2);

    await dao.reorder('c-1', ['b', 'a'], schoolId: null, nowMs: 3);

    expect((await row('b'))!['ordre'], 0);
    expect((await row('a'))!['ordre'], 1);
    final entry = (await outboxById(db))[ProgrammeOutbox.ordreEntry('c-1')]!;
    expect(jsonDecode(entry.payload)['chapitreIds'], ['b', 'a']);
  });
}

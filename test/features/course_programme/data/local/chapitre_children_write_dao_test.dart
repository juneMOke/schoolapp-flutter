import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_children_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../programme_test_fakes.dart';

/// Notes et ressources : ce qui n'est jamais parti se retire sans rien
/// envoyer ; ce que le serveur a se retire par un geste.
void main() {
  late Database db;
  late FakeProgrammeBlobs blobs;
  late ChapitreChildrenWriteDao dao;

  final note = ChapitreNote(
    id: 'n-1',
    chapitreId: 'ch-1',
    texte: 'Séance animée',
    ecriteLe: DateTime.utc(2026, 10, 6),
  );

  setUp(() async {
    db = await openFullOfflineDb();
    blobs = FakeProgrammeBlobs();
    dao = ChapitreChildrenWriteDao(db: db, blobs: blobs);
  });
  tearDown(() => db.close());

  test('une note retirée avant accusé quitte la tablette ; son retrait part '
      'quand même (un ajout en vol a pu être écrit)', () async {
    await dao.addNote(note, coursId: 'c-1', schoolId: null, nowMs: 1);
    final added = (await outboxById(db))[ProgrammeOutbox.noteEntry('n-1')]!;
    expect(added.aggregateId, 'ch-1');

    await dao.deleteNote('n-1', schoolId: null, nowMs: 2);

    expect(await db.query('chapitre_note'), isEmpty);
    final entry = (await outboxById(db))[ProgrammeOutbox.noteEntry('n-1')]!;
    expect(entry.status, OutboxStatus.pending);
    expect(jsonDecode(entry.payload)['op'], 'delete');
  });

  test('une note synchronisée se retire par un geste', () async {
    await dao.addNote(note, coursId: 'c-1', schoolId: null, nowMs: 1);
    await db.update('chapitre_note', {'sync_status': 'SYNCED'});

    await dao.deleteNote('n-1', schoolId: null, nowMs: 2);

    expect((await db.query('chapitre_note')).single['deleted_at'], isNotNull);
    final entry = (await outboxById(db))[ProgrammeOutbox.noteEntry('n-1')]!;
    expect(jsonDecode(entry.payload)['op'], 'delete');
    expect(entry.status, OutboxStatus.pending);
  });

  test('un document scelle son fichier avant sa ligne', () async {
    const ressource = ChapitreRessource(
      id: 'r-1',
      chapitreId: 'ch-1',
      type: RessourceType.document,
      nom: 'Fiche',
      taille: 3,
      mimeType: 'application/pdf',
    );
    final bytes = Uint8List.fromList([1, 2, 3]);

    expect(
      await dao.addRessource(
        ressource,
        coursId: 'c-1',
        bytes: bytes,
        schoolId: null,
        nowMs: 1,
      ),
      isTrue,
    );
    expect(blobs.files['r-1'], bytes);

    blobs.failWrites = true;
    expect(
      await dao.addRessource(
        const ChapitreRessource(
          id: 'r-2',
          chapitreId: 'ch-1',
          type: RessourceType.document,
          nom: 'Perdue',
        ),
        coursId: 'c-1',
        bytes: bytes,
        schoolId: null,
        nowMs: 2,
      ),
      isFalse,
    );
    expect((await db.query('chapitre_ressource')).map((r) => r['id']), ['r-1']);

    await dao.deleteRessource('r-1', schoolId: null, nowMs: 3);
    expect(blobs.files, isEmpty);
  });
}

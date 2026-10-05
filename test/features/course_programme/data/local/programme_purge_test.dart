import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_purge.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _MockBlobs extends Mock implements ProgrammeBlobs {}

/// Un cours réaffecté quitte la tablette avec ses chapitres, leurs enfants,
/// et leurs gestes devenus sans objet.
void main() {
  late Database db;
  late _MockBlobs blobs;

  setUp(() async {
    db = await openFullOfflineDb();
    blobs = _MockBlobs();
    when(() => blobs.reclaimOrphans()).thenAnswer((_) async => 0);
  });
  tearDown(() => db.close());

  Future<void> enqueue(String id, String type, String aggregateId) =>
      OutboxDao(db).enqueue(
        OutboxEntry(
          id: id,
          aggregateType: type,
          aggregateId: aggregateId,
          operation: OutboxOperation.upsert,
          payload: '{}',
          createdAt: 1,
        ),
      );

  test('purgeCours retire tout et neutralise les gestes', () async {
    for (final (id, cours) in [('ch-1', 'c-1'), ('ch-2', 'c-2')]) {
      await db.insert('chapitre', {
        'id': id,
        'cours_id': cours,
        'titre': id,
        'updated_at': 1,
      });
      await db.insert('chapitre_note', {
        'id': 'n-$id',
        'chapitre_id': id,
        'cours_id': cours,
        'texte': 't',
        'ecrite_le': '2026-10-01T08:00:00.000Z',
        'updated_at': 1,
      });
    }
    await enqueue(
      ProgrammeOutbox.chapitreEntry('ch-1'),
      ProgrammeOutbox.chapitreType,
      'ch-1',
    );
    await enqueue(
      ProgrammeOutbox.noteEntry('n-ch-1'),
      ProgrammeOutbox.noteType,
      'ch-1',
    );
    await enqueue(
      ProgrammeOutbox.ordreEntry('c-1'),
      ProgrammeOutbox.ordreType,
      'c-1',
    );
    await enqueue(
      ProgrammeOutbox.chapitreEntry('ch-2'),
      ProgrammeOutbox.chapitreType,
      'ch-2',
    );

    await ProgrammePurge(db: db, blobs: blobs).purgeCours('c-1');

    expect((await db.query('chapitre')).map((r) => r['id']), ['ch-2']);
    expect((await db.query('chapitre_note')).map((r) => r['id']), ['n-ch-2']);
    final pending = await db.query(
      'outbox',
      where: 'status = ?',
      whereArgs: [OutboxStatus.pending.dbValue],
    );
    expect(pending.map((r) => r['id']), [
      ProgrammeOutbox.chapitreEntry('ch-2'),
    ]);
    verify(() => blobs.reclaimOrphans()).called(1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../programme_test_fakes.dart';

/// Les accusés ne défont jamais une saisie plus récente que l'envoi.
void main() {
  late Database db;
  late ProgrammeSyncDao dao;

  const sent = '2026-10-02T08:00:00.000Z';

  ChapitreFicheAck ack({bool ignored = false}) => ChapitreFicheAck(
    chapitre: const ChapitreDto(
      id: 'ch-1',
      coursId: 'c-1',
      ordre: 4,
      titre: 'Titre serveur',
      statut: 'TERMINE',
      seances: 2,
      clientUpdatedAt: '2026-10-03T08:00:00.000Z',
      serverUpdatedAt: '2026-10-03T09:00:00.000Z',
    ),
    ignored: ignored,
  );

  Future<void> seed({String clientUpdatedAt = sent}) => db.insert('chapitre', {
    'id': 'ch-1',
    'cours_id': 'c-1',
    'ordre': 0,
    'titre': 'Titre local',
    'client_updated_at': clientUpdatedAt,
    'server_known': 0,
    'sync_status': 'PENDING_SYNC',
    'updated_at': 1,
  });

  Future<Map<String, Object?>> row() async =>
      (await db.query('chapitre')).single;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ProgrammeSyncDao(db: db, blobs: FakeProgrammeBlobs());
  });
  tearDown(() => db.close());

  test('appliquée : la ligne inchangée passe synchronisée', () async {
    await seed();
    await dao.applyFicheAck(ack(), sentClientUpdatedAt: sent, nowMs: 5);
    final r = await row();
    expect(r['sync_status'], 'SYNCED');
    expect(r['titre'], 'Titre local');
    expect(r['server_known'], 1);
  });

  test('ignorée : la fiche retenue par le serveur s\'applique', () async {
    await seed();
    await dao.applyFicheAck(
      ack(ignored: true),
      sentClientUpdatedAt: sent,
      nowMs: 5,
    );
    final r = await row();
    expect(r['titre'], 'Titre serveur');
    expect(r['sync_status'], 'SYNCED');
    expect(r['ordre'], 0, reason: 'le rang ne vient que du geste d\'ordre');
  });

  test(
    'changée pendant le vol : seule la connaissance serveur se pose',
    () async {
      await seed(clientUpdatedAt: '2026-10-04T08:00:00.000Z');
      await dao.applyFicheAck(
        ack(ignored: true),
        sentClientUpdatedAt: sent,
        nowMs: 5,
      );
      final r = await row();
      expect(r['titre'], 'Titre local');
      expect(r['sync_status'], 'PENDING_SYNC');
      expect(r['server_known'], 1);
      expect(
        await dao.markChapitreRejected(
          'ch-1',
          sentClientUpdatedAt: sent,
          code: 'X',
          nowMs: 6,
        ),
        isFalse,
      );
    },
  );

  test('un ordre accusé ne défait pas un ordre remis en file', () async {
    await seed();
    Future<void> enqueueOrdre(int createdAt) => OutboxDao(db).enqueue(
      OutboxEntry(
        id: ProgrammeOutbox.ordreEntry('c-1'),
        aggregateType: ProgrammeOutbox.ordreType,
        aggregateId: 'c-1',
        operation: OutboxOperation.upsert,
        payload: '{}',
        createdAt: createdAt,
      ),
    );
    await enqueueOrdre(10);
    await dao.applyOrdreAck('c-1', ['x', 'ch-1'], sentCreatedAt: 10, nowMs: 5);
    expect((await row())['ordre'], 1);

    await enqueueOrdre(20);
    await dao.applyOrdreAck('c-1', ['ch-1'], sentCreatedAt: 10, nowMs: 6);
    expect((await row())['ordre'], 1);
  });

  test(
    'anyUnknown : vrai tant qu\'un chapitre cité n\'est pas accusé',
    () async {
      await seed();
      expect(await dao.anyUnknown(['ch-1', 'absent']), isTrue);
      await db.update('chapitre', {'server_known': 1});
      expect(await dao.anyUnknown(['ch-1']), isFalse);
      expect(await dao.chapitreState('absent'), ChapitreServerState.gone);
    },
  );
}

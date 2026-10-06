import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_pull_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

/// La descente ne défait jamais une écriture locale plus récente.
void main() {
  late Database db;
  late ChapitrePullWriter writer;

  ChapitreDto dto({
    String id = 'ch-1',
    int ordre = 3,
    String titre = 'Fractions',
    String clientUpdatedAt = '2026-10-02T08:00:00.000Z',
    List<ChapitreNoteDto> notes = const [],
  }) => ChapitreDto(
    id: id,
    coursId: 'c-1',
    ordre: ordre,
    titre: titre,
    statut: 'EN_COURS',
    seances: 5,
    notes: notes,
    clientUpdatedAt: clientUpdatedAt,
    serverUpdatedAt: '2026-10-02T09:00:00.000Z',
  );

  Future<void> seedLocal({
    required String syncStatus,
    String clientUpdatedAt = '2026-10-03T08:00:00.000Z',
    String? deletedAt,
  }) => db.insert('chapitre', {
    'id': 'ch-1',
    'cours_id': 'c-1',
    'ordre': 0,
    'titre': 'Saisi ici',
    'client_updated_at': clientUpdatedAt,
    'server_known': 0,
    'sync_status': syncStatus,
    'deleted_at': deletedAt,
    'updated_at': 1,
  });

  Future<Map<String, Object?>> row() async =>
      (await db.query('chapitre', where: 'id = ?', whereArgs: ['ch-1'])).single;

  setUp(() async {
    db = await openFullOfflineDb();
    writer = ChapitrePullWriter(db);
  });
  tearDown(() => db.close());

  test('un chapitre neuf est rangé synchronisé et connu du serveur', () async {
    expect(await writer.apply([dto()], nowMs: 7), 1);
    final r = await row();
    expect(r['titre'], 'Fractions');
    expect(r['ordre'], 3);
    expect(r['server_known'], 1);
    expect(r['sync_status'], 'SYNCED');
  });

  test('une fiche locale plus récente reste, mais prend le rang', () async {
    await seedLocal(syncStatus: 'PENDING_SYNC');
    expect(await writer.apply([dto()], nowMs: 7), 0);
    final r = await row();
    expect(r['titre'], 'Saisi ici');
    expect(r['sync_status'], 'PENDING_SYNC');
    expect(r['ordre'], 3);
    expect(r['server_known'], 1);
  });

  test('une fiche serveur plus récente remplace l\'attente', () async {
    await seedLocal(
      syncStatus: 'SYNC_ERROR',
      clientUpdatedAt: '2026-10-01T08:00:00.000Z',
    );
    await writer.apply([dto()], nowMs: 7);
    final r = await row();
    expect(r['titre'], 'Fractions');
    expect(r['sync_status'], 'SYNCED');
  });

  test('une suppression en attente ne bouge pas', () async {
    await seedLocal(
      syncStatus: 'PENDING_SYNC',
      deletedAt: '2026-10-03T08:00:00.000Z',
    );
    await writer.apply([
      dto(clientUpdatedAt: '2026-10-09T08:00:00.000Z'),
    ], nowMs: 7);
    expect((await row())['titre'], 'Saisi ici');
  });

  test('un geste d\'ordre en attente garde le rang local', () async {
    await seedLocal(
      syncStatus: 'SYNCED',
      clientUpdatedAt: '2026-10-01T08:00:00.000Z',
    );
    await OutboxDao(db).enqueue(
      OutboxEntry(
        id: ProgrammeOutbox.ordreEntry('c-1'),
        aggregateType: ProgrammeOutbox.ordreType,
        aggregateId: 'c-1',
        operation: OutboxOperation.update,
        payload: '{}',
        createdAt: 1,
      ),
    );
    await writer.apply([dto()], nowMs: 7);
    final r = await row();
    expect(r['titre'], 'Fractions');
    expect(r['ordre'], 0);
  });

  test('les notes serveur remplacent les synchronisées, pas celles qui '
      'attendent', () async {
    await writer.apply([dto()], nowMs: 7);
    Future<void> note(String id, String status, {String? deletedAt}) =>
        db.insert('chapitre_note', {
          'id': id,
          'chapitre_id': 'ch-1',
          'cours_id': 'c-1',
          'texte': id,
          'ecrite_le': '2026-10-01T08:00:00.000Z',
          'sync_status': status,
          'deleted_at': deletedAt,
          'updated_at': 1,
        });
    await note('n-old', 'SYNCED');
    await note('n-local', 'PENDING_SYNC');
    await note(
      'n-deleting',
      'PENDING_SYNC',
      deletedAt: '2026-10-03T08:00:00.000Z',
    );

    await writer.apply([
      dto(
        notes: const [
          ChapitreNoteDto(
            id: 'n-new',
            texte: 'neuve',
            ecriteLe: '2026-10-02T08:00:00.000Z',
          ),
          ChapitreNoteDto(
            id: 'n-deleting',
            texte: 'x',
            ecriteLe: '2026-10-01T08:00:00.000Z',
          ),
        ],
      ),
    ], nowMs: 8);

    final rows = await db.query('chapitre_note', orderBy: 'id');
    expect(rows.map((r) => r['id']), ['n-deleting', 'n-local', 'n-new']);
    expect(
      rows.firstWhere((r) => r['id'] == 'n-deleting')['deleted_at'],
      isNotNull,
    );
  });
}

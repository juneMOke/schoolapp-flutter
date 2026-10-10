import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_outbox.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_pull_writer.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_purge.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_sync_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_write_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_push.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

void main() {
  late Database db;
  late JournalWriteDao writer;
  late JournalDao dao;

  const sent = '2026-10-12T08:00:00.000Z';
  final entry = JournalEntry(
    id: 'e-1',
    coursId: 'c-1',
    date: DateTime(2026, 10, 12),
    timeSlotId: 's-1',
    chapitreId: 'ch-1',
    fields: const JournalFields(objectif: 'Calculer', contenu: 'Aires'),
    clientUpdatedAt: DateTime.parse(sent),
  );

  JournalEntryDto serverDto({
    String clientUpdatedAt = sent,
    String? chapitreId = 'ch-1',
    String objectif = 'Calculer',
  }) => JournalEntryDto(
    id: 'e-1',
    coursId: 'c-1',
    date: '2026-10-12',
    timeSlotId: 's-1',
    chapitreId: chapitreId,
    fields: JournalFields(objectif: objectif, contenu: 'Aires'),
    clientUpdatedAt: clientUpdatedAt,
    serverUpdatedAt: '2026-10-12T09:00:00.000Z',
  );

  Future<JournalEntry> stored() async =>
      (await dao.entriesOfCours({'c-1'})).single;

  setUp(() async {
    db = await openFullOfflineDb();
    writer = JournalWriteDao(db);
    dao = JournalDao(db);
  });
  tearDown(() => db.close());

  group('écriture locale', () {
    test('range la saisie en attente et la met en file', () async {
      await writer.save(entry, schoolId: 'school', nowMs: 1, authorId: 'u-1');

      final row = await stored();
      expect(row.fields.objectif, 'Calculer');
      expect(row.date, DateTime(2026, 10, 12));
      expect(row.syncState, RecordSyncState.pending);
      final queued = await OutboxDao(db).byId(JournalOutbox.entry('e-1'));
      expect(queued?.aggregateType, JournalOutbox.type);
      expect(queued?.schoolId, 'school');
    });

    test(
      'une seconde saisie remplace la première, en file comme en base',
      () async {
        await writer.save(entry, schoolId: 'school', nowMs: 1);
        await writer.save(
          JournalEntry(
            id: 'e-1',
            coursId: 'c-1',
            date: DateTime(2026, 10, 12),
            timeSlotId: 's-1',
          ),
          schoolId: 'school',
          nowMs: 2,
        );

        expect((await stored()).isBlank, isTrue);
        expect(await OutboxDao(db).pendingCount(), 1);
      },
    );
  });

  group('descente', () {
    test('une entrée inconnue se range synchronisée', () async {
      await JournalPullWriter(db).apply([serverDto()], nowMs: 1);

      expect((await stored()).syncState, RecordSyncState.synced);
    });

    test('une saisie locale plus récente n\'est pas écrasée', () async {
      await writer.save(entry, schoolId: 'school', nowMs: 1);

      final written = await JournalPullWriter(db).apply([
        serverDto(
          clientUpdatedAt: '2026-10-12T07:00:00.000Z',
          objectif: 'Vieux',
        ),
      ], nowMs: 2);

      expect(written, 0);
      expect((await stored()).fields.objectif, 'Calculer');
    });

    test(
      'une version serveur plus récente remplace la saisie en attente',
      () async {
        await writer.save(entry, schoolId: 'school', nowMs: 1);

        await JournalPullWriter(db).apply([
          serverDto(
            clientUpdatedAt: '2026-10-12T10:00:00.000Z',
            objectif: 'Neuf',
          ),
        ], nowMs: 2);

        expect((await stored()).fields.objectif, 'Neuf');
      },
    );
  });

  group('accusé', () {
    test(
      'ligne inchangée : l\'entrée retenue s\'applique, détachement compris',
      () async {
        await writer.save(entry, schoolId: 'school', nowMs: 1);

        await JournalSyncDao(db).applyAck(
          JournalEntryAck(
            entry: serverDto(chapitreId: null),
            superseded: false,
          ),
          sentClientUpdatedAt: sent,
          nowMs: 2,
        );

        final row = await stored();
        expect(row.syncState, RecordSyncState.synced);
        expect(row.chapitreId, isNull);
      },
    );

    test('ligne ressaisie pendant le vol : elle reste en attente', () async {
      await writer.save(entry, schoolId: 'school', nowMs: 1);

      await JournalSyncDao(db).applyAck(
        JournalEntryAck(entry: serverDto(), superseded: false),
        sentClientUpdatedAt: '2026-10-12T06:00:00.000Z',
        nowMs: 2,
      );

      expect((await stored()).syncState, RecordSyncState.pending);
    });

    test('refus : « à corriger », sauf saisie plus récente', () async {
      await writer.save(entry, schoolId: 'school', nowMs: 1);
      final sync = JournalSyncDao(db);

      expect(
        await sync.markRejected(
          'e-1',
          sentClientUpdatedAt: '2026-10-12T06:00:00.000Z',
          code: 'JOURNAL_ENTRY_INCOMPLETE',
          nowMs: 2,
        ),
        isFalse,
      );
      expect(
        await sync.markRejected(
          'e-1',
          sentClientUpdatedAt: sent,
          code: 'JOURNAL_ENTRY_INCOMPLETE',
          nowMs: 2,
        ),
        isTrue,
      );
      final row = await stored();
      expect(row.isRejected, isTrue);
      expect(row.rejectionCode, 'JOURNAL_ENTRY_INCOMPLETE');
    });
  });

  test(
    'purge d\'un cours : ses entrées et ses saisies en attente partent',
    () async {
      await writer.save(entry, schoolId: 'school', nowMs: 1);

      await JournalPurge(db).purgeCours('c-1');

      expect(await dao.entriesOfCours({'c-1'}), isEmpty);
      expect(await OutboxDao(db).pendingCount(), 0);
    },
  );
}

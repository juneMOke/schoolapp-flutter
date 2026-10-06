import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/handlers/chapitre_note_outbox_handler.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/handlers/chapitre_ordre_outbox_handler.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/handlers/chapitre_outbox_handler.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/handlers/chapitre_ressource_outbox_handler.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_transfer_api.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../offline_full_db.dart';
import '../../../programme_test_fakes.dart';

class _MockApi extends Mock implements ProgrammeSyncApi {}

class _MockTransfer extends Mock implements ProgrammeTransferApi {}

class _FakeRessourcePayload extends Fake implements ChapitreRessourcePayload {}

DioException _dio(int status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: detailCode == null ? null : {'detailCode': detailCode},
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late _MockTransfer transfer;
  late FakeProgrammeBlobs blobs;
  late ProgrammeSyncDao dao;
  late List<String> evicted;
  final user = CurrentUserContext()..set('u-1', schoolId: 's-1');
  const extras = <String, dynamic>{};

  setUpAll(() => registerFallbackValue(_FakeRessourcePayload()));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    transfer = _MockTransfer();
    blobs = FakeProgrammeBlobs();
    dao = ProgrammeSyncDao(db: db, blobs: blobs);
    evicted = [];
    await db.insert('chapitre', {
      'id': 'ch-1',
      'cours_id': 'c-1',
      'titre': 'Fractions',
      'client_updated_at': '2026-10-02T08:00:00.000Z',
      'server_known': 0,
      'sync_status': 'PENDING_SYNC',
      'updated_at': 1,
    });
  });
  tearDown(() => db.close());

  Future<void> evict(String coursId) async => evicted.add(coursId);

  OutboxEntry entryOf(String type, Map<String, Object?> payload) => OutboxEntry(
    id: '$type:x',
    aggregateType: type,
    aggregateId: 'ch-1',
    operation: OutboxOperation.upsert,
    payload: jsonEncode(payload),
    schoolId: 's-1',
    createdAt: 1,
  );

  group('fiche', () {
    late ChapitreOutboxHandler handler;
    final save = ChapitreFichePayload.save(
      Chapitre(
        id: 'ch-1',
        coursId: 'c-1',
        ordre: 0,
        titre: 'Fractions',
        clientUpdatedAt: DateTime.utc(2026, 10, 2, 8),
      ),
    );

    setUp(() {
      handler = ChapitreOutboxHandler(
        api: api,
        dao: dao,
        evictCours: evict,
        currentUser: user,
        extras: extras,
        now: () => 9,
      );
    });

    test('accusée : la ligne est synchronisée et connue', () async {
      when(() => api.saveChapitre(extras, any())).thenAnswer(
        (_) async => const ChapitreFicheAck(
          chapitre: ChapitreDto(
            id: 'ch-1',
            coursId: 'c-1',
            ordre: 0,
            titre: 'Fractions',
            statut: 'PLANIFIE',
            seances: 4,
            serverUpdatedAt: '2026-10-02T09:00:00.000Z',
          ),
          ignored: false,
        ),
      );
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.chapitreType, save.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect((await db.query('chapitre')).single['server_known'], 1);
    });

    test('403 COURS_NOT_OWNED : le cours est évincé', () async {
      when(
        () => api.saveChapitre(extras, any()),
      ).thenThrow(_dio(403, detailCode: 'COURS_NOT_OWNED'));
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.chapitreType, save.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(evicted, ['c-1']);
    });

    test('403 sans code : refus, la ligne est à corriger', () async {
      when(() => api.saveChapitre(extras, any())).thenThrow(_dio(403));
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.chapitreType, save.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(evicted, isEmpty);
      expect((await db.query('chapitre')).single['sync_status'], 'SYNC_ERROR');
    });

    test('le corps suit le contrat : {authorId, chapitre: fiche}', () async {
      when(() => api.saveChapitre(extras, any())).thenThrow(_dio(500));
      final entry = OutboxEntry(
        id: 'CHAPITRE:ch-1',
        aggregateType: ProgrammeOutbox.chapitreType,
        aggregateId: 'ch-1',
        operation: OutboxOperation.upsert,
        payload: jsonEncode({...save.toJson(), 'authorId': 'u-1'}),
        schoolId: 's-1',
        createdAt: 1,
      );
      await handler.dispatch(entry);
      final body =
          verify(() => api.saveChapitre(extras, captureAny())).captured.single
              as Map;
      expect(body.keys, unorderedEquals(['authorId', 'chapitre']));
      expect(body['authorId'], 'u-1');
      expect((body['chapitre'] as Map)['id'], 'ch-1');
      expect((body['chapitre'] as Map)['titre'], save.fiche['titre']);
    });

    test('une suppression porte son auteur en paramètre', () async {
      when(
        () => api.deleteChapitre(extras, 'ch-1', 'u-1'),
      ).thenAnswer((_) async {});
      final result = await handler.dispatch(
        OutboxEntry(
          id: 'CHAPITRE:ch-1',
          aggregateType: ProgrammeOutbox.chapitreType,
          aggregateId: 'ch-1',
          operation: OutboxOperation.upsert,
          payload: jsonEncode({
            ...ChapitreFichePayload.delete(
              chapitreId: 'ch-1',
              coursId: 'c-1',
            ).toJson(),
            'authorId': 'u-1',
          }),
          createdAt: 1,
        ),
      );
      expect(result.outcome, OutboxDispatchOutcome.acked);
      verify(() => api.deleteChapitre(extras, 'ch-1', 'u-1')).called(1);
    });

    test('404 nu sur un enregistrement : refus, rien n\'est effacé', () async {
      when(() => api.saveChapitre(extras, any())).thenThrow(_dio(404));
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.chapitreType, save.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(await db.query('chapitre'), hasLength(1));
    });

    test('refus après qu\'une descente a remplacé la ligne : définitif, '
        'pas de rejeu jusqu\'au poison', () async {
      await db.update('chapitre', {
        'client_updated_at': '2026-10-05T08:00:00.000Z',
      });
      when(() => api.saveChapitre(extras, any())).thenThrow(_dio(422));
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.chapitreType, save.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.failed);
    });

    test('une suppression refusée fait réapparaître le chapitre', () async {
      await db.update('chapitre', {
        'server_known': 1,
        'deleted_at': '2026-10-05T08:00:00.000Z',
      });
      when(
        () => api.deleteChapitre(extras, 'ch-1', any()),
      ).thenThrow(_dio(422));
      final result = await handler.dispatch(
        entryOf(
          ProgrammeOutbox.chapitreType,
          ChapitreFichePayload.delete(
            chapitreId: 'ch-1',
            coursId: 'c-1',
          ).toJson(),
        ),
      );
      expect(result.outcome, OutboxDispatchOutcome.failed);
      final row = (await db.query('chapitre')).single;
      expect(row['deleted_at'], isNull);
      expect(row['sync_status'], 'SYNC_ERROR');
    });

    test(
      'un retrait sur un chapitre inconnu du serveur (404) est acquis',
      () async {
        when(
          () => api.deleteChapitre(extras, 'ch-1', any()),
        ).thenThrow(_dio(404));
        final result = await handler.dispatch(
          entryOf(
            ProgrammeOutbox.chapitreType,
            ChapitreFichePayload.delete(
              chapitreId: 'ch-1',
              coursId: 'c-1',
            ).toJson(),
          ),
        );
        expect(result.outcome, OutboxDispatchOutcome.acked);
      },
    );

    test('410 : supprimé ailleurs, la ligne part', () async {
      when(() => api.saveChapitre(extras, any())).thenThrow(_dio(410));
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.chapitreType, save.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await db.query('chapitre'), isEmpty);
    });
  });

  group('enfants', () {
    late ChapitreNoteOutboxHandler notes;
    late ChapitreRessourceOutboxHandler ressources;
    const note = ChapitreNotePayload(
      op: ProgrammePushOp.save,
      id: 'n-1',
      chapitreId: 'ch-1',
      texte: 'Séance',
      ecriteLe: '2026-10-06T08:00:00.000Z',
    );

    setUp(() {
      notes = ChapitreNoteOutboxHandler(
        api: api,
        dao: dao,
        evictCours: evict,
        currentUser: user,
        extras: extras,
      );
      ressources = ChapitreRessourceOutboxHandler(
        api: api,
        transfer: transfer,
        blobs: blobs,
        dao: dao,
        evictCours: evict,
        currentUser: user,
        extras: extras,
      );
    });

    test('un ajout attend son chapitre sans appeler le réseau', () async {
      final result = await notes.dispatch(
        entryOf(ProgrammeOutbox.noteType, note.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.addNote(any(), any()));
    });

    test('le corps suit le contrat : {authorId, note}', () async {
      await db.update('chapitre', {'server_known': 1});
      when(() => api.addNote(extras, any())).thenAnswer((_) async {});
      await notes.dispatch(
        entryOf(ProgrammeOutbox.noteType, {
          ...note.toJson(),
          'authorId': 'u-1',
        }),
      );
      final body =
          verify(() => api.addNote(extras, captureAny())).captured.single
              as Map;
      expect(body.keys, unorderedEquals(['authorId', 'note']));
      expect((body['note'] as Map)['texte'], note.texte);
    });

    test('409 CHAPITRE_NOT_YET_SYNCED : attente, pas refus', () async {
      await db.update('chapitre', {'server_known': 1});
      when(
        () => api.addNote(extras, any()),
      ).thenThrow(_dio(409, detailCode: 'CHAPITRE_NOT_YET_SYNCED'));
      final result = await notes.dispatch(
        entryOf(ProgrammeOutbox.noteType, note.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test(
      'chapitre parti de la tablette : le geste n\'a plus d\'objet',
      () async {
        await db.delete('chapitre');
        final result = await notes.dispatch(
          entryOf(ProgrammeOutbox.noteType, note.toJson()),
        );
        expect(result.outcome, OutboxDispatchOutcome.acked);
      },
    );

    test(
      'document : le fichier part avec sa description ; perdu, refus',
      () async {
        await db.update('chapitre', {'server_known': 1});
        await db.insert('chapitre_ressource', {
          'id': 'r-1',
          'chapitre_id': 'ch-1',
          'cours_id': 'c-1',
          'type': 'document',
          'nom': 'Fiche',
          'sync_status': 'PENDING_SYNC',
          'updated_at': 1,
        });
        final payload = const ChapitreRessourcePayload(
          op: ProgrammePushOp.save,
          chapitreId: 'ch-1',
          ressource: ChapitreRessourceDto(
            id: 'r-1',
            type: 'document',
            nom: 'Fiche',
          ),
        ).toJson();

        final lost = await ressources.dispatch(
          entryOf(ProgrammeOutbox.ressourceType, payload),
        );
        expect(lost.outcome, OutboxDispatchOutcome.failed);
        expect(
          (await db.query('chapitre_ressource')).single['sync_error_code'],
          ChapitreRessourceOutboxHandler.bytesLostCode,
        );

        blobs.files['r-1'] = Uint8List.fromList([1]);
        when(
          () => transfer.putRessource(
            extras,
            any(),
            metadata: any(named: 'metadata'),
            bytes: any(named: 'bytes'),
          ),
        ).thenAnswer((_) async {});
        final sent = await ressources.dispatch(
          entryOf(ProgrammeOutbox.ressourceType, payload),
        );
        expect(sent.outcome, OutboxDispatchOutcome.acked);
        expect(
          (await db.query('chapitre_ressource')).single['sync_status'],
          'SYNCED',
        );
      },
    );
  });

  group('ordre', () {
    late ChapitreOrdreOutboxHandler handler;
    const payload = ChapitreOrdrePayload(
      coursId: 'c-1',
      chapitreIds: ['ch-1'],
      clientUpdatedAt: '2026-10-06T08:00:00.000Z',
    );

    setUp(() {
      handler = ChapitreOrdreOutboxHandler(
        api: api,
        dao: dao,
        evictCours: evict,
        currentUser: user,
        extras: extras,
      );
    });

    test('attend tant qu\'un chapitre cité est inconnu, sans réseau', () async {
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.ordreType, payload.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.reorderChapitres(any(), any(), any()));
    });

    test('l\'ordre retenu s\'applique', () async {
      await db.update('chapitre', {'server_known': 1, 'ordre': 7});
      when(
        () => api.reorderChapitres(extras, 'c-1', any()),
      ).thenAnswer((_) async => const ChapitreOrdreAck(['ch-1']));
      final entry = OutboxEntry(
        id: ProgrammeOutbox.ordreEntry('c-1'),
        aggregateType: ProgrammeOutbox.ordreType,
        aggregateId: 'c-1',
        operation: OutboxOperation.upsert,
        payload: jsonEncode(payload.toJson()),
        createdAt: 1,
      );
      await db.insert('outbox', entry.toMap());

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect((await db.query('chapitre')).single['ordre'], 0);
    });

    test('403 COURS_NOT_OWNED : le cours est évincé', () async {
      await db.update('chapitre', {'server_known': 1});
      when(
        () => api.reorderChapitres(extras, 'c-1', any()),
      ).thenThrow(_dio(403, detailCode: 'COURS_NOT_OWNED'));
      final result = await handler.dispatch(
        entryOf(ProgrammeOutbox.ordreType, payload.toJson()),
      );
      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(evicted, ['c-1']);
    });
  });
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_sync_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_write_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_push_models.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../offline_full_db.dart';

const _author = 'u1';

CoteCellKey _key(String col, {String student = 'e1', bool examen = false}) =>
    CoteCellKey(
      studentId: student,
      coursId: 'fr',
      colonneId: col,
      examen: examen,
    );

/// Le serveur : applique par défaut, ou rend ce qu'on lui dicte par colonne.
class _FakeSyncApi implements CotesSyncApi {
  final requests = <CotesPushRequest>[];
  Object? failure;
  Map<String, Map<String, Object?>> byColumn = {};
  Set<String> silent = {};
  Future<void> Function()? duringFlight;

  @override
  Future<CotesPushResponse> submit(
    Map<String, dynamic> extras,
    CotesPushRequest request,
  ) async {
    requests.add(request);
    final thrown = failure;
    if (thrown != null) throw thrown;
    await duringFlight?.call();
    return CotesPushResponse.fromJson({
      'results': [
        for (final line in request.cotes)
          if (!silent.contains(line.key.colonneId))
            {
              ...line.toJson(),
              'outcome': 'APPLIED',
              ...?byColumn[line.key.colonneId],
            },
      ],
    });
  }
}

DioException _http(int code) {
  final options = RequestOptions();
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: code),
  );
}

void main() {
  late Database db;
  late CotesWriteLocalDataSource write;
  late CotesLocalDataSource read;
  late _FakeSyncApi api;
  late CotesBatchOutboxHandler handler;
  late int clock;

  setUp(() async {
    db = await openFullOfflineDb();
    write = CotesWriteLocalDataSource(db);
    read = CotesLocalDataSource(db);
    api = _FakeSyncApi();
    clock = 5000;
    handler = CotesBatchOutboxHandler(
      api: api,
      localDataSource: write,
      outbox: OutboxDao(db),
      requiredAuth: const {},
      now: () => clock,
    );
  });
  tearDown(() => db.close());

  OutboxEntry entry({int? createdAt}) => cotesOutboxEntry(
    classroomId: 'c1',
    authorId: _author,
    createdAt: createdAt ?? clock,
  );

  Future<int> save(CoteCellKey key, double? value, {int? at}) =>
      write.saveDraft(
        classroomId: 'c1',
        key: key,
        valeur: value,
        authorId: _author,
        nowMs: at ?? clock,
        entry: entry(createdAt: at),
      );

  Future<CoteCell> cell(String col) async =>
      (await read.readCells('c1')).firstWhere((c) => c.key.colonneId == col);

  group('écriture locale', () {
    test('la saisie et son entrée d\'outbox partent ensemble', () async {
      await save(_key('P1'), 14.5);

      final saved = await cell('P1');
      expect(saved.hasDraft, isTrue);
      expect(saved.syncState, SyncState.pendingSync);
      final entries = await OutboxDao(db).pendingReady(clock);
      expect(entries.single.aggregateType, kCotesBatchAggregateType);
      expect(jsonDecode(entries.single.payload)['authorId'], _author);
    });

    test('dix frappes : une seule entrée, un seul brouillon', () async {
      for (var i = 0; i < 10; i++) {
        await save(_key('P1'), i.toDouble());
      }

      expect(await OutboxDao(db).pendingReady(clock), hasLength(1));
      expect((await cell('P1')).draftValue, 9);
    });

    test('l\'horloge est monotone, même si la tablette recule', () async {
      final first = await save(_key('P1'), 10, at: 9000);
      final second = await save(_key('P1'), 11, at: 1000);

      expect(second, first + 1);
    });

    test('l\'horloge bat aussi ce que le serveur a écrit', () async {
      await save(_key('P1'), 10, at: 9000);
      await write.applyServerValue(
        key: _key('P1'),
        pushedAt: 9000,
        valeur: 10,
        serverUpdatedAtMs: 20000,
        superseded: false,
        nowMs: 1,
      );

      expect(await save(_key('P1'), 11, at: 1000), 20001);
    });

    test('une frappe hors barème n\'enfile rien', () async {
      await write.saveInvalid(classroomId: 'c1', key: _key('P1'), raw: '99');

      expect((await cell('P1')).invalidRaw, '99');
      expect(await OutboxDao(db).pendingReady(clock), isEmpty);
    });

    test('une saisie valide efface la frappe hors barème', () async {
      await write.saveInvalid(classroomId: 'c1', key: _key('P1'), raw: '99');
      await save(_key('P1'), 12);

      expect((await cell('P1')).invalidRaw, isNull);
    });
  });

  group('envoi', () {
    test('la ligne porte la bonne colonne et la valeur nulle', () async {
      await save(_key('S1', examen: true), null);

      await handler.dispatch(entry());

      final json = api.requests.single.toJson();
      final line = (json['cotes'] as List).single as Map<String, dynamic>;
      expect(json['authorId'], _author);
      expect(line['periodeScolaireId'], 'S1');
      expect(line['sousPeriodeId'], isNull);
      expect(line['valeur'], isNull);
      expect(line['updatedAt'], isNotNull);
    });

    test('APPLIED : le brouillon devient la valeur du serveur', () async {
      await save(_key('P1'), 14.5);

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final saved = await cell('P1');
      expect(saved.hasDraft, isFalse);
      expect(saved.serverCote, 14.5);
      expect(saved.syncState, SyncState.synced);
    });

    test('une cellule vidée revient au calcul', () async {
      await db.insert('cote_saisie', {
        'student_id': 'e1',
        'cours_id': 'fr',
        'colonne_id': 'P1',
        'classroom_id': 'c1',
        'server_cote': 14.0,
        'calculee': 12.0,
      });
      await save(_key('P1'), null);
      expect((await cell('P1')).displayedValue, 12);

      await handler.dispatch(entry());

      final saved = await cell('P1');
      expect(saved.serverCote, isNull);
      expect(saved.displayedValue, 12);
      expect(saved.isCalculated, isTrue);
    });

    test(
      'SUPERSEDED : la valeur du serveur remplace, signalée une fois',
      () async {
        await save(_key('P1'), 14);
        api.byColumn['P1'] = {'outcome': 'SUPERSEDED', 'valeur': 17.0};

        final result = await handler.dispatch(entry());

        expect(result.outcome, OutboxDispatchOutcome.acked);
        expect((await cell('P1')).serverCote, 17);
        expect(await write.takeSuperseded('c1'), [_key('P1')]);
        expect(await write.takeSuperseded('c1'), isEmpty);
      },
    );

    test('REJECTED : la valeur reste, signalée, hors de la file', () async {
      await save(_key('P1'), 14);
      api.byColumn['P1'] = {'outcome': 'REJECTED', 'reason': 'PERIODE_CLOSE'};

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final saved = await cell('P1');
      expect(saved.isRejected, isTrue);
      expect(saved.draftValue, 14);
      expect(saved.rejectionReason, 'PERIODE_CLOSE');
      expect(await write.pendingCount(classroomId: 'c1', authorId: _author), 0);
    });

    test('renoncer à une cote refusée revient au serveur', () async {
      await save(_key('P1'), 14);
      api.byColumn['P1'] = {'outcome': 'REJECTED', 'reason': 'PERIODE_CLOSE'};
      await handler.dispatch(entry());

      await write.discardRejected(_key('P1'));

      final saved = await cell('P1');
      expect(saved.hasDraft, isFalse);
      expect(saved.isRejected, isFalse);
    });

    test('resaisir une cote refusée la remet en file', () async {
      await save(_key('P1'), 14);
      api.byColumn['P1'] = {'outcome': 'REJECTED', 'reason': 'OUT_OF_RANGE'};
      await handler.dispatch(entry());

      await save(_key('P1'), 15);

      final saved = await cell('P1');
      expect(saved.syncState, SyncState.pendingSync);
      expect(saved.rejectionReason, isNull);
    });

    test('une saisie posée pendant le vol reste à envoyer', () async {
      await save(_key('P1'), 14);
      api.duringFlight = () async {
        api.duringFlight = null;
        await save(_key('P1'), 16);
      };

      await handler.dispatch(entry());

      final saved = await cell('P1');
      expect(saved.draftValue, 16);
      expect(saved.syncState, SyncState.pendingSync);
      // Et une entrée subsiste pour la porter.
      expect(await OutboxDao(db).pendingReady(clock + 1), hasLength(1));
    });

    test('une ligne sans résultat reste en attente et rejoue', () async {
      await save(_key('P1'), 14);
      await save(_key('P2'), 15);
      api.silent = {'P2'};

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.retry);
      expect((await cell('P1')).syncState, SyncState.synced);
      expect((await cell('P2')).syncState, SyncState.pendingSync);
    });

    test('plus de 200 lignes : la tranche suivante est ré-enfilée', () async {
      for (var i = 0; i < 205; i++) {
        await save(_key('C$i'), 10, at: 1000 + i);
      }
      final started = (await OutboxDao(db).pendingReady(clock)).single;

      final result = await handler.dispatch(started);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(api.requests.single.cotes, hasLength(200));
      expect(await write.pendingCount(classroomId: 'c1', authorId: _author), 5);
      final next = (await OutboxDao(db).pendingReady(clock + 1)).single;
      // Un `created_at` neuf : l'accusé de l'entrée partie ne l'emporte pas.
      expect(next.createdAt, isNot(started.createdAt));
    });

    test('rien à envoyer : acquitté sans appel', () async {
      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(api.requests, isEmpty);
    });

    test('seul l\'auteur envoie ses lignes', () async {
      await write.saveDraft(
        classroomId: 'c1',
        key: _key('P1'),
        valeur: 12,
        authorId: 'autre',
        nowMs: clock,
        entry: cotesOutboxEntry(
          classroomId: 'c1',
          authorId: 'autre',
          createdAt: clock,
        ),
      );

      await handler.dispatch(entry());

      expect(api.requests, isEmpty);
    });

    test('charge illisible : refus définitif, sans appel', () async {
      const broken = OutboxEntry(
        id: 'x',
        aggregateType: kCotesBatchAggregateType,
        aggregateId: 'c1',
        operation: OutboxOperation.upsert,
        payload: 'pas du json',
        createdAt: 1,
      );

      final result = await handler.dispatch(broken);

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });
  });

  group('pannes', () {
    Future<OutboxDispatchOutcome> outcomeFor(Object failure) async {
      await save(_key('P1'), 14);
      api.failure = failure;
      return (await handler.dispatch(entry())).outcome;
    }

    test('réseau : la file attend', () async {
      final failure = DioException(requestOptions: RequestOptions());
      expect(await outcomeFor(failure), OutboxDispatchOutcome.retry);
      expect((await cell('P1')).syncState, SyncState.pendingSync);
    });

    test('5xx : la file attend', () async {
      expect(await outcomeFor(_http(503)), OutboxDispatchOutcome.retry);
    });

    test('401 : la file attend la reconnexion', () async {
      expect(await outcomeFor(_http(401)), OutboxDispatchOutcome.retry);
    });

    test('403 : terminal, et la saisie reste sur l\'appareil', () async {
      expect(await outcomeFor(_http(403)), OutboxDispatchOutcome.failed);
      expect((await cell('P1')).draftValue, 14);
    });
  });
}

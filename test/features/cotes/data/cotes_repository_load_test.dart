import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/retrofit.dart' hide Headers;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_write_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_classe_dto.dart';
import 'package:school_app_flutter/features/cotes/data/repositories/cotes_repository_impl.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../offline_full_db.dart';
import 'cote_fixture.dart';

class _FakeConnectivity implements ConnectivityService {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeApi implements CotesApi {
  Object? failure;
  String? seenEtag;
  int calls = 0;
  Map<String, dynamic> json = coteClasseJson();

  @override
  Future<HttpResponse<CoteClasseDto>> loadClasse(
    Map<String, dynamic> extras,
    String classroomId,
    String? ifNoneMatch,
  ) async {
    calls++;
    seenEtag = ifNoneMatch;
    final thrown = failure;
    if (thrown != null) throw thrown;
    return HttpResponse(
      CoteClasseDto.fromJson(json),
      Response(
        requestOptions: RequestOptions(),
        statusCode: 200,
        headers: Headers.fromMap({
          'etag': ['W/"v1"'],
        }),
      ),
    );
  }
}

DioException _status(int code, {Object? error}) {
  final options = RequestOptions();
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: code),
    error: error,
  );
}

/// Après les `updatedAt` de la classe : la réponse est bien plus récente.
final int _now = DateTime.utc(2026, 11, 2).millisecondsSinceEpoch;

void main() {
  late Database db;
  late _FakeApi api;
  late _FakeConnectivity connectivity;
  late CotesLocalDataSource local;
  late CotesRepositoryImpl repository;

  setUp(() async {
    db = await openFullOfflineDb();
    api = _FakeApi();
    connectivity = _FakeConnectivity();
    local = CotesLocalDataSource(db);
    final outbox = OutboxDao(db);
    repository = CotesRepositoryImpl(
      api: api,
      localDataSource: local,
      writeDataSource: CotesWriteLocalDataSource(db),
      syncMetaDao: SyncMetaDao(db),
      connectivity: connectivity,
      outbox: outbox,
      syncEngine: SyncEngine(outbox: outbox, connectivity: connectivity),
      requiredAuth: const {},
      now: () => _now,
    );
  });
  tearDown(() => db.close());

  CoteSnapshot right(dynamic result) => result.fold(
    (failure) => fail('attendu Right, reçu $failure'),
    (snapshot) => snapshot,
  );

  test('premier chargement : sans ETag, en base, marqué frais', () async {
    final snapshot = right(await repository.load('c1'));

    expect(api.seenEtag, isNull);
    expect(snapshot.fromCache, isFalse);
    expect(snapshot.classe.eleves, hasLength(2));
    expect(snapshot.cells, hasLength(3));
  });

  test('rouvrir envoie l\'ETag ; un 304 sert le cache sans erreur', () async {
    await repository.load('c1');
    api.failure = _status(304);

    final snapshot = right(await repository.load('c1'));

    // L'étiquette faible du back repart telle quelle, préfixe compris.
    expect(api.seenEtag, 'W/"v1"');
    expect(snapshot.fromCache, isFalse);
    expect(snapshot.cells, hasLength(3));
  });

  test('sans copie locale, l\'ETag restant n\'est pas envoyé', () async {
    await SyncMetaDao(
      db,
    ).setCursor('cotes_classe:c1', cursor: 'x', syncedAt: 1);

    await repository.load('c1');

    expect(api.seenEtag, isNull);
  });

  test('hors ligne avec cache : la copie, sans appel réseau', () async {
    await repository.load('c1');
    connectivity.online = false;

    final snapshot = right(await repository.load('c1'));

    expect(api.calls, 1);
    expect(snapshot.fromCache, isTrue);
  });

  test('hors ligne sans cache : l\'échec réseau remonte', () async {
    connectivity.online = false;

    final result = await repository.load('c1');

    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
  });

  test('panne serveur avec cache : la copie', () async {
    await repository.load('c1');
    api.failure = _status(500, error: const ServerFailure('boom'));

    expect(right(await repository.load('c1')).fromCache, isTrue);
  });

  test('un 403 remonte même avec un cache', () async {
    await repository.load('c1');
    api.failure = _status(403, error: const UnauthorizedFailure());

    final result = await repository.load('c1');

    expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
  });

  test('une réponse illisible sans cache : erreur serveur', () async {
    api.failure = const FormatException('x');

    final result = await repository.load('c1');

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('recharger efface ce que le serveur ne dit plus', () async {
    await repository.load('c1');
    api.json = coteClasseJson()..['cellules'] = <Object?>[];

    final cells = right(await repository.load('c1')).cells;

    expect(cells.every((c) => c.displayedValue == null), isTrue);
  });

  test('un champ mal typé avec un cache : la copie, pas une erreur', () async {
    await repository.load('c1');
    api.failure = TypeError();

    expect(right(await repository.load('c1')).fromCache, isTrue);
  });

  test('une réponse partie avant un envoi accepté ne l\'efface pas', () async {
    await repository.load('c1');
    await db.update(
      'cote_saisie',
      {'server_cote': 19.0, 'server_updated_at': _now + 1},
      where: 'colonne_id = ?',
      whereArgs: ['P1'],
    );

    final cells = right(await repository.load('c1')).cells;

    final cell = cells.firstWhere((c) => c.key.colonneId == 'P1');
    expect(cell.serverCote, 19);
    expect(cell.calculee, 13.25);
  });

  test('une cellule dépassée attend son signalement', () async {
    await repository.load('c1');
    await db.update(
      'cote_saisie',
      {'superseded_at': 1},
      where: 'colonne_id = ?',
      whereArgs: ['S1'],
    );
    api.json = coteClasseJson()..['cellules'] = <Object?>[];

    final cells = right(await repository.load('c1')).cells;

    expect(cells.firstWhere((c) => c.key.colonneId == 'S1').serverCote, 31);
  });

  test(
    'une cote refusée et une frappe à corriger survivent au rechargement',
    () async {
      await repository.load('c1');
      await db.update(
        'cote_saisie',
        {
          'has_draft': 1,
          'draft_valeur': 18.0,
          'sync_status': 'SYNC_ERROR',
          'rejection_reason': 'PERIODE_CLOSE',
        },
        where: 'colonne_id = ?',
        whereArgs: ['P1'],
      );
      await db.update(
        'cote_saisie',
        {'invalid_raw': '99'},
        where: 'colonne_id = ?',
        whereArgs: ['P2'],
      );
      api.json = coteClasseJson()..['cellules'] = <Object?>[];

      final cells = right(await repository.load('c1')).cells;
      final refused = cells.firstWhere((c) => c.key.colonneId == 'P1');
      expect(refused.isRejected, isTrue);
      expect(refused.draftValue, 18);
      // Le serveur n'en dit plus rien : sa part est effacée, le brouillon reste.
      expect(refused.serverCote, isNull);
    },
  );
}

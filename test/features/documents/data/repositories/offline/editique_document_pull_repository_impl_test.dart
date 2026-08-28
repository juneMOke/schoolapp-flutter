import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/documents/data/datasources/offline/editique_document_pull_api.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_cipher.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_store.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_key_service.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_maintenance_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/data/models/editique_document_pull_models.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../offline_full_db.dart';

class _MockApi extends Mock implements EditiqueDocumentPullApi {}

/// Habilitation pilotable — la MÊME instance sert le repository et le cache,
/// comme en production (une seule autorité enregistrée dans le conteneur).
class _FakeAccess implements EditiqueCacheAccess {
  bool entitled = true;

  @override
  Future<bool> isEntitled() async => entitled;
}

class _FakeKeyService implements EditiqueCacheKeyService {
  @override
  Future<EditiqueCacheKey> getOrCreate() async => EditiqueCacheKey(
    bytes: Uint8List.fromList(List<int>.generate(32, (i) => i & 0xFF)),
    createdNow: false,
  );

  @override
  Future<void> destroy() async {}
}

class _FakeIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'gen-${++_next}';
}

/// Rend la main dès que [condition] est vraie, sinon au bout de [delai].
///
/// ⚠️ Ne JAMAIS remplacer par un `pumpEventQueue()` nu : celui-ci ne draine que
/// vingt tours d'event-loop, or un cycle de pull traverse deux lectures SQLite
/// réelles avant d'atteindre l'API. Sur une machine chargée ces I/O ne rendent
/// pas la main dans ces vingt tours, et le test rougissait alors qu'il n'avait
/// simplement pas assez attendu (CI de la PR #35 : `Expected: ['cycle-1']`,
/// `Actual: []`). On attend donc l'ÉVÉNEMENT, jamais un nombre de tours.
///
/// [exigee] distingue les deux usages : `true` pour une condition qui DOIT
/// survenir (son absence est un échec), `false` pour laisser à un comportement
/// fautif toute sa chance de se manifester — on sort tôt s'il se manifeste, et
/// l'assertion qui suit tranche.
Future<void> _attendreQue(
  bool Function() condition, {
  required String quoi,
  bool exigee = true,
  Duration delai = const Duration(seconds: 5),
}) async {
  final butoir = DateTime.now().add(delai);
  while (!condition()) {
    if (DateTime.now().isAfter(butoir)) {
      if (exigee) fail('délai dépassé en attendant que $quoi');
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
}

/// Le cycle de pull du catalogue des pièces scellées.
///
/// Ce qui gouverne ce fichier : **le curseur ne franchit jamais ce qui n'a pas
/// été gardé.** Un curseur avancé sur des lignes que le cache a refusées rend
/// ces pièces définitivement inatteignables — le serveur répondra « rien de
/// neuf » pour toujours, et seul un rembobinage de `sync_meta` le réparerait.
///
/// Le cache monté ici est le VRAI : c'est lui qui refuse **en bloc**
/// (`recordKnownDocuments` sort sur `return 0` avant sa boucle), et c'est de ce
/// refus-là que naît le défaut. Un faux qui refuserait ligne à ligne
/// raconterait une autre histoire.
void main() {
  late Database db;
  late Directory base;
  late _MockApi api;
  late SyncMetaDao syncMeta;
  late EditiqueCacheDao index;
  late _FakeAccess access;
  late CurrentUserContext currentUser;
  late EditiqueDocumentPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const schoolId = 'school-1';
  final cursorKey = editiqueDocumentsCursorKey(schoolId);

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    base = await Directory.systemTemp.createTemp('eteelo-editique-pull-repo-');
    api = _MockApi();
    syncMeta = SyncMetaDao(db);
    index = EditiqueCacheDao(db);
    access = _FakeAccess();
    currentUser = CurrentUserContext()..set('u-1', schoolId: schoolId);
    repo = EditiqueDocumentPullRepositoryImpl(
      api: api,
      cache: EditiqueDocumentCache(
        index: index,
        maintenance: EditiqueCacheMaintenanceDao(db),
        store: EditiqueBlobStore(
          keyService: _FakeKeyService(),
          cipher: runEditiqueCipherTask,
          baseDirectory: () async => base,
        ),
        ids: _FakeIds(),
        access: access,
        now: () => 1000,
      ),
      syncMetaDao: syncMeta,
      currentUser: currentUser,
      requiredAuth: auth,
      access: access,
      now: () => 9000,
    );
  });

  tearDown(() async {
    await db.close();
    if (await base.exists()) await base.delete(recursive: true);
  });

  EditiqueDocumentPullOutcome right(
    Either<Failure, EditiqueDocumentPullOutcome> e,
  ) => e.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

  HttpResponse<T> httpOk<T>(T body) => HttpResponse(
    body,
    Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
  );

  DioException statut(int code) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
    ),
  );

  PulledEditiqueDocument piece(String id, String numero) =>
      PulledEditiqueDocument(
        id: id,
        docType: 'NP',
        documentNumber: numero,
        studentId: 's-1',
        sizeBytes: 4096,
      );

  EditiqueDocumentPageDto page(
    List<PulledEditiqueDocument> items, {
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => EditiqueDocumentPageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-08-15T10:00:00Z',
    ),
  );

  group('le curseur ne franchit jamais ce qui n\'a pas été gardé', () {
    test('porteur non habilité : le catalogue reste atteignable — rien n\'est '
        'demandé au réseau et le curseur en base ne bouge pas', () async {
      await syncMeta.setCursor(cursorKey, cursor: 'wm-connu', syncedAt: 111);
      access.entitled = false;

      final outcome = right(await repo.syncDocuments());

      verifyNever(() => api.pullEditiqueDocuments(any(), any(), any()));
      expect(
        await syncMeta.getCursor(cursorKey),
        'wm-connu',
        reason: 'un curseur avancé ici condamnerait le porteur suivant',
      );
      expect(
        await syncMeta.getSyncedAt(cursorKey),
        111,
        reason: '`sync_meta` n\'est pas touché du tout, fraîcheur comprise',
      );
      expect(outcome.cursor, 'wm-connu');
      expect(await index.count(), 0);
    });

    test('porteur habilité : le cycle part et le curseur avance', () async {
      when(() => api.pullEditiqueDocuments(auth, null, 100)).thenAnswer(
        (_) async => httpOk(
          page([piece('d-1', 'ETL-NP-2526-000001')], nextWatermark: 'wm-1'),
        ),
      );

      final outcome = right(await repo.syncDocuments());

      expect(outcome.upserted, 1);
      expect(outcome.notModified, isFalse);
      expect(outcome.cursor, 'wm-1');
      expect(
        outcome.serverTimeMs,
        DateTime.parse('2026-08-15T10:00:00Z').millisecondsSinceEpoch,
      );
      expect(await syncMeta.getCursor(cursorKey), 'wm-1');
      expect(await index.findByDocumentId('d-1'), isNotNull);
    });

    // Le scénario du terrain : la tablette du guichet passe de main en main.
    test('après le passage d\'un porteur non habilité, le porteur habilité '
        'suivant reçoit tout le catalogue', () async {
      when(() => api.pullEditiqueDocuments(auth, null, 100)).thenAnswer(
        (_) async => httpOk(
          page([
            piece('d-1', 'ETL-NP-2526-000001'),
            piece('d-2', 'ETL-NP-2526-000002'),
          ], nextWatermark: 'wm-tete'),
        ),
      );
      // Ce que le serveur répond à qui repart de la tête du catalogue :
      // plus rien, et pour toujours.
      when(
        () => api.pullEditiqueDocuments(auth, 'wm-tete', 100),
      ).thenAnswer((_) async => httpOk(page(const [])));

      // 1ᵉʳ temps — l'enseignant. Il n'a droit à rien, il n'obtient rien.
      access.entitled = false;
      await repo.syncDocuments();

      // 2ᵉ temps — la secrétaire, sur la même tablette.
      access.entitled = true;
      final outcome = right(await repo.syncDocuments());

      expect(outcome.upserted, 2);
      expect(
        await index.count(),
        2,
        reason: 'ces pièces ont été scellées avant sa prise de poste',
      );
      expect(await index.findByDocumentId('d-1'), isNotNull);
      expect(await index.findByDocumentId('d-2'), isNotNull);
      verifyNever(() => api.pullEditiqueDocuments(auth, 'wm-tete', 100));
    });

    // Rien n'a échoué : on s'est abstenu. Un `Left` ferait re-tenter le
    // coordinateur en boucle sur un refus qui ne changera pas.
    test(
      'l\'abstention se rapporte en notModified, jamais en erreur',
      () async {
        access.entitled = false;

        final result = await repo.syncDocuments();

        expect(result.isRight(), isTrue);
        final outcome = right(result);
        expect(outcome.notModified, isTrue);
        expect(outcome.upserted, 0);
        expect(outcome.cursor, isNull, reason: 'aucun curseur encore mémorisé');
        expect(outcome.syncedAt, 9000);
      },
    );
  });

  group('le cycle keyset lui-même', () {
    test('multi-pages : le curseur est mémorisé à CHAQUE page', () async {
      String? vuAvantLaPage2;
      when(() => api.pullEditiqueDocuments(auth, null, 100)).thenAnswer(
        (_) async => httpOk(
          page(
            [piece('d-1', 'ETL-NP-2526-000001')],
            nextCursor: 'k1',
            hasMore: true,
          ),
        ),
      );
      when(() => api.pullEditiqueDocuments(auth, 'k1', 100)).thenAnswer((
        _,
      ) async {
        vuAvantLaPage2 = await syncMeta.getCursor(cursorKey);
        return httpOk(
          page([piece('d-2', 'ETL-NP-2526-000002')], nextWatermark: 'wm-2'),
        );
      });

      final outcome = right(await repo.syncDocuments());

      expect(
        vuAvantLaPage2,
        'k1',
        reason: 'une coupure ici reprend à la page 2, pas au début',
      );
      expect(outcome.upserted, 2);
      expect(await syncMeta.getCursor(cursorKey), 'wm-2');
      expect(await index.count(), 2);
    });

    test(
      '400 : curseur illisible ou forgé → rebootstrap depuis null',
      () async {
        await syncMeta.setCursor(cursorKey, cursor: 'forge', syncedAt: 111);
        when(
          () => api.pullEditiqueDocuments(auth, 'forge', 100),
        ).thenThrow(statut(400));
        when(() => api.pullEditiqueDocuments(auth, null, 100)).thenAnswer(
          (_) async => httpOk(
            page([
              piece('d-1', 'ETL-NP-2526-000001'),
            ], nextWatermark: 'wm-neuf'),
          ),
        );

        final outcome = right(await repo.syncDocuments());

        expect(outcome.upserted, 1);
        expect(await syncMeta.getCursor(cursorKey), 'wm-neuf');
        expect(await index.findByDocumentId('d-1'), isNotNull);
      },
    );

    test('sans école courante : rien n\'est tiré, une entrée descendue serait '
        'introuvable', () async {
      currentUser.clear();

      final result = await repo.syncDocuments();

      expect(
        result.fold((f) => f, (o) => o),
        isA<ValidationFailure>(),
        reason: 'l\'école est la portée de lecture d\'une entrée de cache',
      );
      verifyNever(() => api.pullEditiqueDocuments(any(), any(), any()));
    });

    test(
      'cycles sérialisés : le second attend le premier au lieu de rembobiner '
      'le curseur',
      () async {
        final journal = <String>[];
        final ecluse = Completer<void>();
        when(() => api.pullEditiqueDocuments(auth, null, 100)).thenAnswer((
          _,
        ) async {
          journal.add('cycle-1');
          await ecluse.future;
          return httpOk(
            page([piece('d-1', 'ETL-NP-2526-000001')], nextWatermark: 'wm-1'),
          );
        });
        when(() => api.pullEditiqueDocuments(auth, 'wm-1', 100)).thenAnswer((
          _,
        ) async {
          journal.add('cycle-2');
          return httpOk(
            page([piece('d-2', 'ETL-NP-2526-000002')], nextWatermark: 'wm-2'),
          );
        });

        final premier = repo.syncDocuments();
        final second = repo.syncDocuments();

        // 1) Attendre que le PREMIER cycle ait réellement atteint l'API : il
        //    est alors parqué sur l'écluse, son curseur pas encore persisté.
        //    C'est cette étape que `pumpEventQueue()` ne garantissait pas.
        await _attendreQue(
          () => journal.isNotEmpty,
          quoi: 'le premier cycle atteigne l\'API',
        );

        // 2) Laisser au SECOND toutes ses chances de démarrer à tort. Sans
        //    sérialisation il relit le curseur — toujours null, le premier
        //    n'ayant rien persisté — et rappelle la MÊME route, ce qui
        //    inscrirait « cycle-1 » une seconde fois. On sort dès qu'il
        //    bronche ; l'assertion qui suit trancherait de toute façon.
        await _attendreQue(
          () => journal.length > 1,
          quoi: 'le second cycle démarre',
          exigee: false,
          delai: const Duration(milliseconds: 300),
        );

        expect(journal, [
          'cycle-1',
        ], reason: 'le second cycle n\'a pas encore lu le curseur');

        ecluse.complete();
        await premier;
        await second;

        expect(journal, ['cycle-1', 'cycle-2']);
        expect(
          await syncMeta.getCursor(cursorKey),
          'wm-2',
          reason: 'le second est reparti de ce que le premier avait persisté',
        );
        expect(await index.count(), 2);
      },
    );
  });
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/documents/data/datasources/offline/editique_document_pull_api.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';

/// Préfixe de la clé `sync_meta` du curseur de pull des pièces scellées, et
/// nom de la ressource pour le `PullCoordinator`.
///
/// **Non scopé par compte** : une pièce est un document d'établissement, et deux
/// agents du même guichet partagent le même catalogue. Scoper par uid ferait
/// re-télécharger l'inventaire entier à chaque changement de porteur.
///
/// **Scopé par école**, en revanche — voir [editiqueDocumentsCursorKey]. Le
/// flux, lui, est cadré par l'école du jeton : garder un curseur unique sur une
/// tablette réaffectée ferait reprendre le delta de la nouvelle école au point
/// où l'ancienne s'était arrêtée, et tout ce qui a été scellé avant ce point ne
/// descendrait jamais.
const String kEditiqueDocumentsResource = 'editique_documents';

/// Clé du curseur pour une école donnée. Le séparateur `@` est la convention du
/// dépôt pour une ressource scopée.
String editiqueDocumentsCursorKey(String schoolId) =>
    '$kEditiqueDocumentsResource@$schoolId';

/// Issue d'un cycle de pull éditique.
class EditiqueDocumentPullOutcome {
  final int upserted;
  final bool notModified;
  final int syncedAt;
  final String? cursor;
  final int? serverTimeMs;

  const EditiqueDocumentPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  factory EditiqueDocumentPullOutcome.notModifiedAt(
    int syncedAt,
    String? cursor,
  ) => EditiqueDocumentPullOutcome(
    upserted: 0,
    notModified: true,
    syncedAt: syncedAt,
    cursor: cursor,
  );
}

/// Page keyset incohérente : `hasMore` annoncé sans curseur qui progresse.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Issue d'un cycle + le seul signal exploitable par un rejeu (un curseur 400
/// est dissoluble par bootstrap).
class _CycleAttempt {
  final Either<Failure, EditiqueDocumentPullOutcome> result;
  final bool rejectedCursor;

  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET des pièces scellées (L3.4) — miroir *lecture* de
/// `GET /api/v1/sync/editique-documents` (lot back B3).
///
/// Ce que ce flux change : jusqu'ici le cache ne contenait que ce que **cette**
/// tablette avait émis ou consulté. Un reçu encaissé au guichet d'à côté lui
/// restait invisible. Le delta lui apprend ce qui existe ; les octets, eux,
/// continuent d'être tirés un par un — **jamais** dans une page de delta.
///
/// Le curseur opaque est mémorisé à CHAQUE page : une coupure au milieu d'un
/// bootstrap de plusieurs milliers de pièces reprend où elle s'est arrêtée au
/// lieu de tout recommencer.
///
/// Aucun drapeau de bootstrap complet : rien ici n'en dépend. Une connaissance
/// partielle du catalogue n'est pas un état faux — c'est simplement moins de
/// pièces proposées à la consultation, et le cycle suivant complète.
class EditiqueDocumentPullRepositoryImpl {
  final EditiqueDocumentPullApi _api;
  final EditiqueDocumentCache _cache;
  final SyncMetaDao _syncMetaDao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  final EditiqueCacheAccess _access;

  static const String resource = kEditiqueDocumentsResource;
  static const int pageLimit = 100;

  EditiqueDocumentPullRepositoryImpl({
    required EditiqueDocumentPullApi api,
    required EditiqueDocumentCache cache,
    required SyncMetaDao syncMetaDao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
    required EditiqueCacheAccess access,
    Clock now = systemClock,
  }) : _api = api,
       _cache = cache,
       _syncMetaDao = syncMetaDao,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth,
       _access = access,
       _now = now;

  /// Sérialise les cycles : deux cycles concurrents rembobineraient le curseur.
  Future<Either<Failure, EditiqueDocumentPullOutcome>>? _tail;

  Future<Either<Failure, EditiqueDocumentPullOutcome>> syncDocuments() {
    final prev = _tail;
    late final Future<Either<Failure, EditiqueDocumentPullOutcome>> scheduled;
    final run = prev == null ? _pull() : prev.then((_) => _pull());
    scheduled = run.whenComplete(() {
      if (identical(_tail, scheduled)) _tail = null;
    });
    _tail = scheduled;
    return scheduled;
  }

  Future<Either<Failure, EditiqueDocumentPullOutcome>> _pull() async {
    // L'école est la portée de lecture d'une entrée de cache : sans elle, les
    // lignes descendues seraient introuvables. On ne tire donc rien.
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(ValidationFailure('Aucune école courante'));
    }

    final syncedAt = _now();
    final cursorKey = editiqueDocumentsCursorKey(schoolId);
    final stored = await _syncMetaDao.getCursor(cursorKey); // null = bootstrap

    // ⚠️ LE CURSEUR NE FRANCHIT JAMAIS CE QUI N'A PAS ÉTÉ GARDÉ.
    //
    // La garde d'habilitation était posée six fois — à l'écriture de l'index, à
    // la lecture, dans les deux use cases du catalogue, à l'ouverture de
    // session — mais jamais ici. Le cycle partait donc, descendait le catalogue
    // entier, `recordKnownDocuments` sortait sur un `return 0` avant même sa
    // boucle (le refus est en BLOC, jamais ligne à ligne), et le curseur était
    // persisté quand même, page après page.
    //
    // Le coût n'est pas le trafic : c'est que ces pièces ne seront **jamais
    // redemandées**. Le curseur se retrouve à la tête du catalogue avec un index
    // vide, et le porteur suivant — entitlé, lui — repart de cette tête. Son
    // catalogue reste vide pour tout ce qui a été scellé avant, définitivement.
    // Ni l'élargissement de la liste, ni une mise à jour d'APK n'y changent quoi
    // que ce soit : seul un rembobinage de `sync_meta` le répare.
    //
    // On sort donc AVANT le premier appel, sans toucher `sync_meta`. Le rapport
    // reste honnête — rien de neuf, aucun octet consommé.
    //
    // ⚠️ Ne surtout PAS coder cela en « ne pas persister si rien n'a été
    // retenu » : une page légitimement vide retient zéro elle aussi, et le
    // curseur cesserait d'avancer sur un cycle parfaitement sain.
    if (!await _access.isEntitled()) {
      return Right(EditiqueDocumentPullOutcome.notModifiedAt(syncedAt, stored));
    }

    final first = await _attemptCycle(syncedAt, schoolId, from: stored);
    // 400 = curseur illisible, forgé, ou émis pour une autre ressource →
    // repartir du bootstrap. Hors du `catch` : une exception dans un `catch`
    // s'échapperait de `_pull`, qui promet de ne jamais lever.
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(cursorKey, cursor: null, syncedAt: syncedAt);
      return (await _attemptCycle(syncedAt, schoolId, from: null)).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle(
    int syncedAt,
    String schoolId, {
    required String? from,
  }) async {
    try {
      return _CycleAttempt(
        Right(await _runCycle(syncedAt, schoolId, from: from)),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        // Rien de neuf : jeton relu, pas réécrit depuis `from` — un 304 peut
        // tomber en cours de cycle, après une progression déjà persistée.
        final kept = await _syncMetaDao.getCursor(
          editiqueDocumentsCursorKey(schoolId),
        );
        await _syncMetaDao.setCursor(
          editiqueDocumentsCursorKey(schoolId),
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(EditiqueDocumentPullOutcome.notModifiedAt(syncedAt, kept)),
        );
      }
      return _CycleAttempt(
        Left(ServerFailure(e.message ?? e.toString())),
        rejectedCursor: status == 400,
      );
    } on _IncoherentKeysetPage catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Incoherent keyset page: hasMore without a cursor')),
      );
    } on FormatException catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Invalid editique-documents pull payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  Future<EditiqueDocumentPullOutcome> _runCycle(
    int syncedAt,
    String schoolId, {
    required String? from,
  }) async {
    var cursor = from;
    var upserted = 0;
    String? lastServerTime;

    while (true) {
      final sent = cursor;
      final response = await _api.pullEditiqueDocuments(
        _requiredAuth,
        sent,
        pageLimit,
      );
      final data = response.data;
      lastServerTime = data.page.serverTime;

      upserted += await _cache.recordKnownDocuments([
        for (final document in data.items)
          document.toCacheEntry(schoolId: schoolId, nowMs: syncedAt),
      ]);

      final nextToken = data.page.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      await _syncMetaDao.setCursor(
        editiqueDocumentsCursorKey(schoolId),
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!data.page.hasMore) break; // dernière page du cycle

      // Anti-boucle : le keyset est strictement croissant, donc `hasMore` sans
      // curseur qui avance signale un serveur défaillant. On LÈVE — sortir en
      // silence compterait la tablette comme synchronisée.
      if (data.page.nextCursor == null || data.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    return upserted == 0
        ? EditiqueDocumentPullOutcome.notModifiedAt(syncedAt, cursor)
        : EditiqueDocumentPullOutcome(
            upserted: upserted,
            notModified: false,
            syncedAt: syncedAt,
            cursor: cursor,
            serverTimeMs: EpochIsoHelper.tryToEpochMs(lastServerTime),
          );
  }
}

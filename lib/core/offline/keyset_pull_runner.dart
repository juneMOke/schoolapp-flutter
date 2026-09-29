import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';

/// Ce qu'un cycle de descente keyset a produit.
class KeysetPullResult {
  /// Lignes appliquées sur l'ensemble des pages du cycle.
  final int upserted;

  /// Horloge serveur de la dernière page, en millisecondes, si lisible.
  final int? serverTimeMs;

  const KeysetPullResult({required this.upserted, this.serverTimeMs});

  /// Rien de neuf : un 304, ou un cycle dont aucune page n'a rien appliqué.
  bool get notModified => upserted == 0;
}

/// Récupère une page à partir d'un curseur (`null` = depuis le début). Lève la
/// `DioException` du transport telle quelle : un 304 y est un statut, pas une
/// panne, et c'est le runner qui le lit.
typedef KeysetPageFetcher<I> =
    Future<KeysetPageDto<I>> Function(String? cursor);

/// Applique les lignes d'une page ; rend le nombre de lignes écrites.
typedef KeysetPageApplier<I> =
    Future<int> Function(List<I> items, int syncedAtMs);

/// Le squelette de descente keyset, **une fois** — les modules plus anciens le
/// recopiaient chacun (`_attempt` / `_cycle`).
///
/// Trois gardes, reprises à l'identique de ces copies :
/// - **reprise par page** : le curseur est mémorisé après chaque page, un poste
///   interrompu reprend là où il s'était arrêté ;
/// - **curseur rejeté** (400 : jeton illisible, forgé, d'une autre ressource) :
///   repli sur une descente complète, une seule fois, sinon le jeton fautif
///   serait rejoué à chaque cycle ;
/// - **anti-boucle** : `hasMore` sans curseur neuf est un serveur défaillant ;
///   on lève plutôt que de rejouer la même page à l'infini.
///
/// Un 304 garde le curseur mémorisé **relu**, jamais celui du départ : un 304
/// en cours de cycle rembobinerait derrière les pages déjà appliquées.
class KeysetPullRunner {
  final SyncMetaDao _syncMeta;
  final Clock _now;

  const KeysetPullRunner(this._syncMeta, {Clock now = systemClock})
    : _now = now;

  /// Descend la ressource dont le curseur vit sous [cursorKey] (une clé déjà
  /// scopée par école). [label] ne sert qu'aux messages d'échec.
  Future<Either<Failure, KeysetPullResult>> run<I>({
    required String cursorKey,
    required String label,
    required KeysetPageFetcher<I> fetch,
    required KeysetPageApplier<I> apply,
  }) async {
    final syncedAt = _now();
    final stored = await _syncMeta.getCursor(cursorKey);

    final first = await _attempt(
      cursorKey,
      label,
      syncedAt,
      stored,
      fetch,
      apply,
    );
    if (first.rejectedCursor && stored != null) {
      await _syncMeta.setCursor(cursorKey, cursor: null, syncedAt: syncedAt);
      return (await _attempt(
        cursorKey,
        label,
        syncedAt,
        null,
        fetch,
        apply,
      )).result;
    }
    return first.result;
  }

  Future<_Attempt> _attempt<I>(
    String cursorKey,
    String label,
    int syncedAt,
    String? from,
    KeysetPageFetcher<I> fetch,
    KeysetPageApplier<I> apply,
  ) async {
    try {
      return _Attempt(
        Right(await _cycle(cursorKey, syncedAt, from, fetch, apply)),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        final kept = await _syncMeta.getCursor(cursorKey);
        await _syncMeta.setCursor(cursorKey, cursor: kept, syncedAt: syncedAt);
        return const _Attempt(Right(KeysetPullResult(upserted: 0)));
      }
      return _Attempt(
        Left(ServerFailure(e.message ?? e.toString())),
        rejectedCursor: status == 400,
      );
    } on _IncoherentKeysetPage {
      return _Attempt(
        Left(
          ServerFailure(
            '$label : page keyset incohérente (hasMore sans curseur)',
          ),
        ),
      );
    } catch (_) {
      return _Attempt(
        Left(ServerFailure('$label : réponse de pull illisible')),
      );
    }
  }

  Future<KeysetPullResult> _cycle<I>(
    String cursorKey,
    int syncedAt,
    String? from,
    KeysetPageFetcher<I> fetch,
    KeysetPageApplier<I> apply,
  ) async {
    var cursor = from;
    var upserted = 0;
    String? lastServerTime;

    while (true) {
      final sent = cursor;
      final page = await fetch(sent);
      lastServerTime = page.page.serverTime;
      upserted += await apply(page.items, syncedAt);

      final next = page.page.cursorToPersist;
      if (next != null) cursor = next;
      await _syncMeta.setCursor(cursorKey, cursor: cursor, syncedAt: syncedAt);

      if (!page.page.hasMore) break;
      if (page.page.nextCursor == null || page.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    return KeysetPullResult(
      upserted: upserted,
      serverTimeMs: EpochIsoHelper.tryToEpochMs(lastServerTime),
    );
  }
}

class _Attempt {
  final Either<Failure, KeysetPullResult> result;
  final bool rejectedCursor;

  const _Attempt(this.result, {this.rejectedCursor = false});
}

class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_write_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';

/// Préfixe de l'ETag d'une classe dans `sync_meta`. Le contenu ne dépend pas du
/// compte : toute personne autorisée reçoit la même classe.
const String kCotesClasseResourcePrefix = 'cotes_classe';

class CotesRepositoryImpl implements CotesRepository {
  final CotesApi _api;
  final CotesLocalDataSource _local;
  final CotesWriteLocalDataSource _write;
  final SyncMetaDao _syncMetaDao;
  final ConnectivityService _connectivity;
  final OutboxDao _outbox;
  final SyncEngine _syncEngine;
  final CurrentUserContext? _currentUser;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  const CotesRepositoryImpl({
    required CotesApi api,
    required CotesLocalDataSource localDataSource,
    required CotesWriteLocalDataSource writeDataSource,
    required SyncMetaDao syncMetaDao,
    required ConnectivityService connectivity,
    required OutboxDao outbox,
    required SyncEngine syncEngine,
    required Map<String, dynamic> requiredAuth,
    CurrentUserContext? currentUser,
    Clock now = systemClock,
  }) : _api = api,
       _local = localDataSource,
       _write = writeDataSource,
       _syncMetaDao = syncMetaDao,
       _connectivity = connectivity,
       _outbox = outbox,
       _syncEngine = syncEngine,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth,
       _now = now;

  @override
  Future<Either<Failure, CoteSnapshot>> load(String classroomId) async {
    final resource = '$kCotesClasseResourcePrefix:$classroomId';
    try {
      final cached = await _local.readClasse(classroomId);
      if (!await _connectivity.isOnline()) {
        return _fromCacheOr(classroomId, cached, const NetworkFailure());
      }
      // Sans copie locale, un `304` ne laisserait rien à afficher.
      final etag = cached == null
          ? null
          : await _syncMetaDao.getCursor(resource);
      return await _fetch(classroomId, resource, cached, etag);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  Future<Either<Failure, CoteSnapshot>> _fetch(
    String classroomId,
    String resource,
    CoteClasse? cached,
    String? etag,
  ) async {
    final syncedAt = _now();
    try {
      final response = await _api.loadClasse(_requiredAuth, classroomId, etag);
      await _local.replaceClasse(
        classroomId: classroomId,
        dto: response.data,
        syncedAt: syncedAt,
      );
      await _syncMetaDao.setCursor(
        resource,
        cursor: response.response.headers.value('etag'),
        syncedAt: syncedAt,
      );
      return Right(
        CoteSnapshot(
          classe: response.data.toEntity(),
          cells: await _local.readCells(classroomId),
          fromCache: false,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 304 && cached != null) {
        await _syncMetaDao.setCursor(
          resource,
          cursor: etag,
          syncedAt: syncedAt,
        );
        return Right(
          CoteSnapshot(
            classe: cached,
            cells: await _local.readCells(classroomId),
            fromCache: false,
          ),
        );
      }
      final failure = ApiErrorParser.failureOf(e);
      if (failure is NetworkFailure || failure is ServerFailure) {
        return _fromCacheOr(classroomId, cached, failure);
      }
      return Left(failure);
    } on FormatException {
      return _fromCacheOr(
        classroomId,
        cached,
        const ServerFailure('Invalid cotes payload'),
      );
    }
  }

  Future<Either<Failure, CoteSnapshot>> _fromCacheOr(
    String classroomId,
    CoteClasse? cached,
    Failure failure,
  ) async {
    if (cached == null) return Left(failure);
    return Right(
      CoteSnapshot(
        classe: cached,
        cells: await _local.readCells(classroomId),
        fromCache: true,
      ),
    );
  }

  String get _authorId => _currentUser?.uid ?? '';

  @override
  Future<Either<Failure, Unit>> saveValue({
    required String classroomId,
    required CoteCellKey key,
    required double? value,
  }) => _guard(() async {
    final nowMs = _now();
    await _write.saveDraft(
      classroomId: classroomId,
      key: key,
      valeur: value,
      authorId: _authorId,
      nowMs: nowMs,
      entry: cotesOutboxEntry(
        classroomId: classroomId,
        authorId: _authorId,
        createdAt: nowMs,
      ),
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> saveInvalid({
    required String classroomId,
    required CoteCellKey key,
    required String raw,
  }) => _guard(() async {
    await _write.saveInvalid(classroomId: classroomId, key: key, raw: raw);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> clearInvalid(CoteCellKey key) =>
      _guard(() async {
        await _write.clearInvalid(key);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> discardRejected(CoteCellKey key) =>
      _guard(() async {
        await _write.discardRejected(key);
        return unit;
      });

  @override
  Future<Either<Failure, List<CoteCell>>> readCells(String classroomId) =>
      _guard(() => _local.readCells(classroomId));

  @override
  Future<Either<Failure, List<CoteCellKey>>> takeSuperseded(
    String classroomId,
  ) => _guard(() => _write.takeSuperseded(classroomId));

  @override
  Future<int> pendingCount(String classroomId) =>
      _write.pendingCount(classroomId: classroomId, authorId: _authorId);

  @override
  Future<CoteFlushOutcome> flush(String classroomId) async {
    final report = await _syncEngine.flush();
    if (await pendingCount(classroomId) == 0) return CoteFlushOutcome.done;
    if (report.offline) return CoteFlushOutcome.offline;
    if (report.authBlocked) return CoteFlushOutcome.sessionExpired;
    if (report.skipped) return CoteFlushOutcome.busy;
    return CoteFlushOutcome.stuck;
  }

  @override
  Future<void> retry(String classroomId) => _outbox.enqueue(
    cotesOutboxEntry(
      classroomId: classroomId,
      authorId: _authorId,
      createdAt: _now(),
    ),
  );

  @override
  void Function() addFlushListener(void Function() listener) =>
      _syncEngine.addFlushCompleteListener(listener);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

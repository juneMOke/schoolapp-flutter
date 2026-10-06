import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_copie_log_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_copie_log_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/copie_log_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_copie_repository.dart';

/// Journal des copies : lu en local, chaque diffusion écrite avec son entrée
/// d'outbox (une par ligne) dans une transaction, puis envoyée.
class EvaluationCopieRepositoryImpl implements EvaluationCopieRepository {
  final EvaluationCopieLogLocalDataSource _local;
  final IdGenerator _ids;
  final CurrentUserContext? _currentUser;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const EvaluationCopieRepositoryImpl({
    required EvaluationCopieLogLocalDataSource localDataSource,
    required IdGenerator idGenerator,
    CurrentUserContext? currentUser,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _local = localDataSource,
       _ids = idGenerator,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  @override
  Future<Either<Failure, List<CopieDiffusion>>> getCopieLog(
    String evaluationId,
  ) async {
    try {
      final rows = await _local.getForEvaluation(evaluationId);
      return Right([for (final row in rows) ?row.toEntity()]);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CopieDiffusion>> logDiffusion(
    String evaluationId, {
    required CopieKind kind,
    CopieCanal? canal,
    required bool corrige,
  }) async {
    try {
      final nowMs = _now();
      final row = CopieLogRow(
        id: _ids.newId(),
        evaluationId: evaluationId,
        kind: kind.apiValue,
        // Le contrat : pas de canal pour une impression, un canal pour un
        // partage.
        canal: kind == CopieKind.share
            ? (canal ?? CopieCanal.systeme).apiValue
            : null,
        corrige: corrige,
        occurredAt: nowMs,
        authorUserId: _currentUser?.uid,
        syncStatus: SyncState.pendingSync.dbValue,
      );
      await _local.insertWithOutbox(
        row,
        outboxEntry: OutboxEntry(
          id: '$kEvaluationCopieLogAggregateType:${row.id}',
          aggregateType: kEvaluationCopieLogAggregateType,
          aggregateId: row.id,
          operation: OutboxOperation.create,
          payload: CopieLogPushRequestModel(
            authorId: _currentUser?.uid,
            entry: row,
          ).toJsonString(),
          createdAt: nowMs,
        ),
      );
      final engine = _syncEngine;
      if (engine != null) unawaited(engine.flush());
      return Right(row.toEntity()!);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

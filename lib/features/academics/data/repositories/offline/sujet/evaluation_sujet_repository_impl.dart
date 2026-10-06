import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_sujet_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_sujet_repository.dart';

/// Sujet d'une évaluation, sous-agrégat LWW de la ligne `evaluation` : lu en
/// local, écrit en local `PENDING_SYNC` avec son entrée d'outbox (une par
/// évaluation, remplacée à chaque enregistrement), puis envoyé.
class EvaluationSujetRepositoryImpl implements EvaluationSujetRepository {
  final EvaluationSujetLocalDataSource _local;
  final CurrentUserContext? _currentUser;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const EvaluationSujetRepositoryImpl({
    required EvaluationSujetLocalDataSource localDataSource,
    CurrentUserContext? currentUser,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _local = localDataSource,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  /// Id d'outbox déterministe, un par évaluation : un nouvel enregistrement
  /// remplace l'entrée en attente.
  static String outboxId(String evaluationId) =>
      '$kEvaluationSujetAggregateType:$evaluationId';

  @override
  Future<Either<Failure, EvaluationSujet>> getSujet(String evaluationId) async {
    try {
      final row = await _local.getSujet(evaluationId);
      if (row == null) return const Left(NotFoundFailure());
      return Right(row.toEntity());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EvaluationSujet>> saveSujet(
    String evaluationId, {
    required EvaluationCadre cadre,
    required List<SujetQuestion> questions,
    double? maxPoints,
  }) => _write(
    evaluationId,
    EvaluationSujetRow.fromEntity(cadre, questions),
    maxPoints: maxPoints,
    sendMax: true,
  );

  @override
  Future<Either<Failure, EvaluationSujet>> resendSujetWithoutMax(
    String evaluationId,
  ) async {
    try {
      final current = await _local.getSujet(evaluationId);
      if (current == null) return const Left(NotFoundFailure());
      return _write(evaluationId, current, sendMax: false);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  /// Écrit [sujet] en attente, horodaté, et enfile son envoi. [sendMax] :
  /// le corps porte le maximum local (égal à celui du serveur, il ne change
  /// rien) ; sinon il est omis et le serveur garde le sien.
  Future<Either<Failure, EvaluationSujet>> _write(
    String evaluationId,
    EvaluationSujetRow sujet, {
    double? maxPoints,
    required bool sendMax,
  }) async {
    try {
      final nowMs = _now();
      final row = EvaluationSujetRow(
        dureeMinutes: sujet.dureeMinutes,
        programme: sujet.programme,
        consignes: sujet.consignes,
        questions: sujet.questions,
        updatedAt: nowMs,
        syncStatus: SyncState.pendingSync.dbValue,
      );
      final saved = await _local.saveSujet(
        evaluationId: evaluationId,
        sujet: row,
        maxPoints: maxPoints,
        buildOutboxEntry: (localMax) => OutboxEntry(
          id: outboxId(evaluationId),
          aggregateType: kEvaluationSujetAggregateType,
          aggregateId: evaluationId,
          operation: OutboxOperation.update,
          payload: SujetPushRequestModel(
            evaluationId: evaluationId,
            authorId: _currentUser?.uid,
            clientUpdatedAt: nowMs,
            maxPoints: sendMax ? localMax : null,
            sujet: row,
          ).toJsonString(),
          createdAt: nowMs,
        ),
      );
      if (!saved) return const Left(NotFoundFailure());
      final engine = _syncEngine;
      if (engine != null) unawaited(engine.flush());
      return Right(row.toEntity());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

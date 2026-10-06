import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_sujet_repository.dart';

/// Sujet d'une évaluation, sous-agrégat LWW de la ligne `evaluation` : lu en
/// local, écrit en local `PENDING_SYNC`.
class EvaluationSujetRepositoryImpl implements EvaluationSujetRepository {
  final EvaluationSujetLocalDataSource _local;
  final Clock _now;

  const EvaluationSujetRepositoryImpl({
    required EvaluationSujetLocalDataSource localDataSource,
    Clock now = systemClock,
  }) : _local = localDataSource,
       _now = now;

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
  }) async {
    try {
      final row = EvaluationSujetRow.fromEntity(
        cadre,
        questions,
        updatedAt: _now(),
        syncStatus: SyncState.pendingSync.dbValue,
      );
      final saved = await _local.saveSujet(
        evaluationId: evaluationId,
        sujet: row,
        maxPoints: maxPoints,
      );
      if (!saved) return const Left(NotFoundFailure());
      return Right(row.toEntity());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

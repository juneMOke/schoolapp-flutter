import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_sujet_repository.dart';

/// Sujet d'une évaluation, lu en local (sous-agrégat LWW de la ligne
/// `evaluation`).
class EvaluationSujetRepositoryImpl implements EvaluationSujetRepository {
  final EvaluationSujetLocalDataSource _local;

  const EvaluationSujetRepositoryImpl({
    required EvaluationSujetLocalDataSource localDataSource,
  }) : _local = localDataSource;

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
}

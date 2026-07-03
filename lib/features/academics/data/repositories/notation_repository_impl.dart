import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/saisir_note_request_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/notation_repository.dart';

/// Implémentation de [NotationRepository] : délègue au [CourseRemoteDataSource]
/// (réutilisé), mappe les erreurs Dio → [Failure] (via l'interceptor projet) et
/// convertit les modèles en entités.
class NotationRepositoryImpl implements NotationRepository {
  final CourseRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const NotationRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<NoteEleve>>> getNotesEleves(
    String evaluationId,
  ) async {
    try {
      final models = await remoteDataSource.getNotesEleves(
        requiredAuth,
        evaluationId,
      );
      return Right(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, NoteEvaluation>> saisirNote(
    String evaluationId,
    SaisirNoteRequest request,
  ) async {
    try {
      final model = await remoteDataSource.saisirNote(
        requiredAuth,
        evaluationId,
        SaisirNoteRequestModel.fromDomain(request),
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}

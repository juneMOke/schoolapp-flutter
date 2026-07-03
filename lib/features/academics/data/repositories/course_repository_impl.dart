// `dartz` exporte aussi un type `Evaluation` : on le masque au profit de notre
// entité domaine.
import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/create_evaluation_request_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const CourseRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<CourseSummary>>> getMyCourses() async {
    try {
      final models = await remoteDataSource.getMyCourses(requiredAuth);
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
  Future<Either<Failure, CoursNotationDetail>> getCoursNotationDetail(
    String coursId,
  ) async {
    try {
      final model = await remoteDataSource.getCoursNotationDetail(
        requiredAuth,
        coursId,
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

  @override
  Future<Either<Failure, Evaluation>> createEvaluation(
    String coursId,
    CreateEvaluationRequest request,
  ) async {
    try {
      final model = await remoteDataSource.createEvaluation(
        requiredAuth,
        coursId,
        CreateEvaluationRequestModel.fromDomain(request),
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

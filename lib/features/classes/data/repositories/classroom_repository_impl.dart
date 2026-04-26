import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/data/datasources/classroom_remote_data_source.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';

class ClassroomRepositoryImpl implements ClassroomRepository {
  final ClassroomRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const ClassroomRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<Classroom>>> getClassroomsByLevelAndAcademicYear({
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource
          .listClassroomsByLevelAndAcademicYear(
            requiredAuth,
            schoolLevelGroupId,
            schoolLevelId,
            academicYearId,
          );

      return Right(models.map((model) => model.toEntity()).toList());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid classroom payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}

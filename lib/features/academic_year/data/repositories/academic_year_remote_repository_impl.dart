import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/data/datasources/academic_year_remote_data_source.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_remote_repository.dart';

class AcademicYearRemoteRepositoryImpl implements AcademicYearRemoteRepository {
  final AcademicYearRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const AcademicYearRemoteRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, AcademicYear>> getAcademicYearBySchoolId({
    required String schoolId,
  }) async {
    try {
      final model = await remoteDataSource.getAcademicYearBySchoolId(
        requiredAuth,
        schoolId,
      );
      return Right(model.toAcademicYear());
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

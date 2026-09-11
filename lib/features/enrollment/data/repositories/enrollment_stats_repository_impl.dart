import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

class EnrollmentStatsRepositoryImpl implements EnrollmentStatsRepository {
  final EnrollmentRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const EnrollmentStatsRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, EnrollmentStats>> getEnrollmentStats({
    EnrollmentStatsWindow window = const EnrollmentStatsWindow.year(),
  }) async {
    try {
      final response = await remoteDataSource.getEnrollmentStats(
        requiredAuth,
        window.apiPeriod,
        window.apiDate,
        window.apiFrom,
        window.apiTo,
      );
      return Right(response.toEntity());
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
  Future<Either<Failure, PaginatedResponse<DayEnrollmentEntry>>> getEntries({
    required EnrollmentStatsWindow window,
    required int page,
    required int size,
    required EnrollmentEntriesOrder order,
  }) async {
    try {
      final response = await remoteDataSource.getEntries(
        requiredAuth,
        window.apiPeriod,
        window.apiDate,
        window.apiFrom,
        window.apiTo,
        page,
        size,
        order.apiValue,
      );
      return Right(response.toEntity());
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

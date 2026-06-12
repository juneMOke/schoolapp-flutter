import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/data/remote/attendance_stats_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_stats_repository.dart';

class AttendanceStatsRepositoryImpl implements AttendanceStatsRepository {
  final AttendanceStatsRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const AttendanceStatsRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, StudentAttendanceSummary>>
  getStudentAttendanceSummary({
    required String studentId,
    StatsPeriod period = StatsPeriod.year,
    String? month,
    String? week,
  }) async {
    try {
      final model = await remoteDataSource.getStudentAttendanceSummary(
        requiredAuth,
        studentId,
        period.apiValue,
        month,
        week,
      );

      return Right(model.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid attendance summary payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}

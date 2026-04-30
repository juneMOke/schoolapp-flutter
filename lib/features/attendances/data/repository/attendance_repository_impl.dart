import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/data/models/daily_attendance_command_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/attendance_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceForClass({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource.listAttendanceForClass(
        requiredAuth,
        classroomId,
        _formatDate(date),
        academicYearId,
      );

      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid attendance payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> recordDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
    required List<AttendanceUpdate> updates,
  }) async {
    try {
      final command = DailyAttendanceCommandModel.fromDomain(
        classroomId: classroomId,
        date: date,
        academicYearId: academicYearId,
        updates: updates,
      );

      await remoteDataSource.recordDailyAttendance(requiredAuth, command);
      return const Right(null);
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_session_request_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_time_slot_request_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const ScheduleRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, WeeklyTimetable>> getMyTimetable(
    String academicYearId,
  ) async {
    try {
      final model = await remoteDataSource.getMyTimetable(
        requiredAuth,
        academicYearId,
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
  Future<Either<Failure, WeeklyTimetable>> getClassroomGrid(
    String classroomId,
    String academicYearId,
  ) async {
    try {
      final model = await remoteDataSource.getClassroomGrid(
        requiredAuth,
        classroomId,
        academicYearId,
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
  Future<Either<Failure, TimeSlot>> createTimeSlot(
    CreateTimeSlotRequest request,
  ) async {
    try {
      final model = await remoteDataSource.createTimeSlot(
        requiredAuth,
        CreateTimeSlotRequestModel.fromDomain(request),
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
  Future<Either<Failure, Session>> createSession(
    CreateSessionRequest request,
  ) async {
    try {
      final model = await remoteDataSource.createSession(
        requiredAuth,
        CreateSessionRequestModel.fromDomain(request),
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
  Future<Either<Failure, Unit>> deleteSession(String sessionId) async {
    try {
      await remoteDataSource.deleteSession(requiredAuth, sessionId);
      return const Right(unit);
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

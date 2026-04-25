import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/data/datasources/student_charges_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';

class StudentChargesRepositoryImpl implements StudentChargesRepository {
  final StudentChargesRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const StudentChargesRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<StudentCharge>>> getStudentCharges({
    required String studentId,
    required String levelId,
  }) async {
    try {
      final models = await remoteDataSource.initializeChargesForStudent(
        requiredAuth,
        studentId,
        levelId,
      );
      return Right(models.map((m) => m.toEntity()).toList());
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
  Future<Either<Failure, List<StudentCharge>>>
  getStudentChargesByAcademicYear({
    required String studentId,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource
          .listStudentChargesByStudentAndAcademicYear(
            requiredAuth,
            studentId,
            academicYearId,
          );
      return Right(models.map((m) => m.toEntity()).toList());
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
  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByChargeId({required String chargeId}) async {
    try {
      final models = await remoteDataSource.listPaymentAllocationsByChargeId(
        requiredAuth,
        chargeId,
      );
      return Right(models.map((model) => model.toEntity()).toList());
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
  Future<Either<Failure, StudentCharge>> updateStudentChargeExpectedAmount({
    required String studentChargeId,
    required String studentId,
    required double expectedAmountInCents,
  }) async {
    if (expectedAmountInCents <= 0 ||
        expectedAmountInCents != expectedAmountInCents.roundToDouble()) {
      return const Left(ValidationFailure('Invalid request data'));
    }

    try {
      final model = await remoteDataSource.updateStudentChargeExpectedAmount(
        requiredAuth,
        studentChargeId,
        studentId,
        expectedAmountInCents.toInt(),
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

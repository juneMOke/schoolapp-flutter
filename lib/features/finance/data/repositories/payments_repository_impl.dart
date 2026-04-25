import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/data/datasources/payments_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const PaymentsRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByStudentAndAcademicYear({
    required String studentId,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource.listPaymentsByStudentAndAcademicYear(
        requiredAuth,
        studentId,
        academicYearId,
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
  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByPaymentId({required String paymentId}) async {
    try {
      final models = await remoteDataSource.listPaymentAllocationsByPaymentId(
        requiredAuth,
        paymentId,
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
}
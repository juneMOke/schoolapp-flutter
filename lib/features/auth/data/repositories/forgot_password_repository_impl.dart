import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/data/datasources/forgot_password_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/models/generate_otp_request_model.dart';
import 'package:school_app_flutter/features/auth/data/models/validate_otp_request_model.dart';
import 'package:school_app_flutter/features/auth/domain/entities/reset_token.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/forgot_password_repository.dart';

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  final ForgotPasswordRemoteDataSource remoteDataSource;

  ForgotPasswordRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> generateOtp({required String userEmail}) async {
    try {
      await remoteDataSource.generateOtp(
        GenerateOtpRequestModel(userEmail: userEmail),
      );
      return const Right(null);
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
  Future<Either<Failure, ResetToken>> validateOtp({
    required String userEmail,
    required String code,
  }) async {
    try {
      final response = await remoteDataSource.validateOtp(
        ValidateOtpRequestModel(userEmail: userEmail, code: code),
      );
      return Right(ResetToken(value: response.token));
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

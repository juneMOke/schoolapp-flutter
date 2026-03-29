import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/reset_token.dart';

abstract class ForgotPasswordRepository {
  Future<Either<Failure, void>> generateOtp({required String userEmail});

  Future<Either<Failure, ResetToken>> validateOtp({
    required String userEmail,
    required String code,
  });
}

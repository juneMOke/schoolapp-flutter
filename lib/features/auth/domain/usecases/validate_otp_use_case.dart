import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/reset_token.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/forgot_password_repository.dart';

class ValidateOtpUseCase {
  final ForgotPasswordRepository _repository;

  const ValidateOtpUseCase(this._repository);

  Future<Either<Failure, ResetToken>> call({
    required String email,
    required String code,
  }) {
    return _repository.validateOtp(userEmail: email, code: code);
  }
}

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String newPassword,
    required String otpToken,
  }) {
    return _repository.resetPassword(
      email: email,
      newPassword: newPassword,
      otpToken: otpToken,
    );
  }
}

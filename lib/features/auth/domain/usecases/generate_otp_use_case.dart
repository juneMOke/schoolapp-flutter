import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/forgot_password_repository.dart';

class GenerateOtpUseCase {
  final ForgotPasswordRepository _repository;

  const GenerateOtpUseCase(this._repository);

  Future<Either<Failure, void>> call({required String email}) {
    return _repository.generateOtp(userEmail: email);
  }
}

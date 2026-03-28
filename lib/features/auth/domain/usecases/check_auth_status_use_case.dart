import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository _repository;

  const CheckAuthStatusUseCase(this._repository);

  Future<Either<Failure, AuthSession?>> call() async {
    final isAuthResult = await _repository.isAuthenticated();

    Failure? authFailure;
    bool isAuthenticated = false;

    isAuthResult.fold(
      (failure) => authFailure = failure,
      (value) => isAuthenticated = value,
    );

    if (authFailure != null) return Left(authFailure!);
    if (!isAuthenticated) return const Right(null);

    return _repository.getCurrentSession();
  }
}

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, bool>> isAuthenticated();

  Future<Either<Failure, AuthSession?>> getCurrentSession();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String newPassword,
    required String otpToken,
  });
}

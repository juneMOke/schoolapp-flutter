import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session_snapshot.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  });

  /// Login **hors ligne** (ADR-010 D-01/D-02) : refusé si aucune session locale
  /// pour ce compte (jamais vu online sur ce device).
  Future<Either<Failure, AuthSessionSnapshot>> loginOffline({
    required String email,
    required String password,
  });

  /// Vrai si un utilisateur a déjà été vu online sur ce device (gate D-01).
  Future<bool> hasLocalUser(String email);

  Future<Either<Failure, bool>> isAuthenticated();

  Future<Either<Failure, AuthSession?>> getCurrentSession();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String newPassword,
    required String otpToken,
  });
}

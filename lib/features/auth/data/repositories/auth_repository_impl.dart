import 'dart:io' show SocketException;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:school_app_flutter/features/auth/data/jwt_claims.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/models/login_request_model.dart';
import 'package:school_app_flutter/features/auth/data/models/reset_password_request_model.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session_snapshot.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final AuthSessionManager sessionManager;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.sessionManager,
  });

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        LoginRequestModel(email: email, password: password),
      );
      final session = response.toAuthSession(
        nowMs: DateTime.now().millisecondsSinceEpoch,
      );
      await localDataSource.saveSession(session);
      // Ancre la session offline (vérificateur Argon2id + auth_local). Best-effort :
      // un échec ici n'invalide pas un login online réussi.
      try {
        await sessionManager.persistOnlineLogin(session, password);
      } catch (_) {}
      return Right(session);
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      // Le `NetworkFailure` est le DÉCLENCHEUR du repli login offline (bloc) :
      // ne le produire que pour une vraie absence de réseau. Un statut HTTP non
      // mappé par l'interceptor (ex. 429 rate-limit, 3xx inattendu) signifie
      // que le serveur a répondu — basculer offline là-dessus contournerait le
      // rate-limit et afficherait des bandeaux mensongers.
      return _isNetworkError(e)
          ? const Left(NetworkFailure('Network error occurred'))
          : const Left(ServerFailure('Unexpected error occurred'));
    } on StorageFailure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  static bool _isNetworkError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      (e.type == DioExceptionType.unknown && e.error is SocketException);

  @override
  Future<Either<Failure, AuthSessionSnapshot>> loginOffline({
    required String email,
    required String password,
  }) async {
    // Filet d'exception (revue adversariale) : le chemin offline traverse
    // sqflite, un isolate Argon2 et le secure storage — un throw non attrapé
    // (ex. PlatformException BAD_DECRYPT après restauration de backup)
    // remonterait dans le handler du bloc sans emit → spinner infini.
    try {
      return await sessionManager.loginOffline(
        email: email,
        password: password,
      );
    } catch (_) {
      return const Left(StorageFailure('Offline login failed'));
    }
  }

  @override
  Future<bool> hasLocalUser(String email) async {
    try {
      return await sessionManager.hasLocalUser(email);
    } catch (_) {
      // Base illisible = pas de profil local exploitable → le bloc affichera
      // l'erreur réseau du login online, sans tenter le repli.
      return false;
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final session = await localDataSource.getSession();
      if (session == null) return const Right(false);
      if (session.accessToken.isNotEmpty && isTokenValid(session.accessToken)) {
        return const Right(true);
      }
      // Access vide (session ouverte offline par déconsignation) ou périmé (le
      // TTL access se compte en heures) : la session reste exploitable tant
      // qu'un refresh token VIVANT permet de minter — c'est exactement ce que
      // fait l'interceptor au premier appel. Sans cette branche, une session
      // ouverte hors ligne ne survivait pas au redémarrage de l'app : l'agent
      // était renvoyé sur l'écran de connexion alors que ses jetons étaient là.
      //
      // L'invariant ADR-010 « unauthenticated ⇒ zéro jeton vivant » tient
      // toujours : un logout, une révocation ou un refresh rejeté effacent les
      // jetons (le refresh consigné, lui, reste verrouillé par mot de passe et
      // n'est PAS lu ici) — il n'y a donc plus rien à minter dans ces cas.
      final refreshToken = session.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        return const Right(false);
      }
      final bound = session.refreshExpiresAt;
      // Borne absente (backend qui ne la fournit pas) : le refresh fait foi.
      if (bound == null) return const Right(true);
      return Right(DateTime.now().millisecondsSinceEpoch < bound);
    } catch (_) {
      return const Left(StorageFailure('Failed to read session'));
    }
  }

  @override
  Future<Either<Failure, AuthSession?>> getCurrentSession() async {
    try {
      final session = await localDataSource.getSession();
      return Right(session);
    } catch (_) {
      return const Left(StorageFailure('Failed to read session'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Wipe complet : jetons + `auth_local_session`. L'outbox et
      // `auth_local_user` (invariant « vu sur ce device ») restent intacts.
      await sessionManager.wipeSession();
      await localDataSource.clearSession();
      return const Right<Failure, void>(null);
    } catch (_) {
      return const Left(StorageFailure('Failed to clear session'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String newPassword,
    required String otpToken,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        ResetPasswordRequest(userEmail: email, newPassword: newPassword),
        token: 'Bearer $otpToken',
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

  bool isTokenValid(String token) => JwtClaims.isNotExpired(token);
}

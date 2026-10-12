import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';

/// Un appel **en ligne** rendu en `Either` : l'intercepteur range sa [Failure]
/// dans l'erreur Dio (403 → [UnauthorizedFailure], 401 →
/// [InvalidCredentialsFailure], 422 → [ApiValidationFailure]…) ; sans
/// réponse, c'est le réseau.
///
/// Toute autre exception — une réponse illisible — devient une
/// [ServerFailure] : elle ne doit pas laisser un écran en chargement.
Future<Either<Failure, T>> guardOnline<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on DioException catch (e) {
    return Left(ApiErrorParser.failureOf(e));
  } on FormatException catch (e) {
    return Left(ServerFailure(e.message));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

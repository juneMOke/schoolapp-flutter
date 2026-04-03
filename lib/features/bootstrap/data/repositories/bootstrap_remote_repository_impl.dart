import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/data/datasources/bootstrap_remote_data_source.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_remote_repository.dart';

class BootstrapRemoteRepositoryImpl implements BootstrapRemoteRepository {
  final BootstrapRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const BootstrapRemoteRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, Bootstrap>> getBootstrap() async {
    try {
      final model = await remoteDataSource.getBootstrap(requiredAuth);
      return Right(model.toEntity());
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

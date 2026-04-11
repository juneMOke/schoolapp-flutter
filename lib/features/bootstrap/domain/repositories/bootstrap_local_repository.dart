import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';

abstract class BootstrapLocalRepository {
  Future<Either<Failure, Bootstrap>> getStoredBootstrap(String key);

  Future<Either<Failure, void>> saveBootstrap({
    required Bootstrap bootstrap,
    required String key,
  });

  Future<Either<Failure, void>> clearBootstrap(String key);
}

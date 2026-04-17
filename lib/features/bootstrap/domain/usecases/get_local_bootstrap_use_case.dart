import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';

class GetLocalBootstrapUseCase {
  final BootstrapLocalRepository _repository;

  const GetLocalBootstrapUseCase(this._repository);

  Future<Either<Failure, Bootstrap>> call(String key) {
    return _repository.getStoredBootstrap(key);
  }
}

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';

class ClearLocalBootstrapUseCase {
  final BootstrapLocalRepository _repository;

  const ClearLocalBootstrapUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.clearBootstrap();
  }
}

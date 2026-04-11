import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';

class SaveLocalBootstrapUseCase {
  final BootstrapLocalRepository _repository;

  const SaveLocalBootstrapUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required Bootstrap bootstrap,
    required String key,
  }) {
    return _repository.saveBootstrap(bootstrap: bootstrap, key: key);
  }
}

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_remote_repository.dart';

class GetRemoteBootstrapUseCase {
  final BootstrapRemoteRepository _repository;

  const GetRemoteBootstrapUseCase(this._repository);

  Future<Either<Failure, Bootstrap>> call() {
    return _repository.getBootstrap();
  }
}

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';

abstract class BootstrapRemoteRepository {
  Future<Either<Failure, Bootstrap>> getBootstrapCurrentYear();
  Future<Either<Failure, Bootstrap>> getBootstrapPreviousYear();
}

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';

/// Lit le fichier du personnel sur la tablette.
class LoadStaffFileUseCase {
  final StaffRepository _repository;

  const LoadStaffFileUseCase(this._repository);

  Future<Either<Failure, StaffFileSnapshot>> call() => _repository.loadFile();
}

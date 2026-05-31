import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';

class GetClassroomStatsUseCase {
  final ClassroomRepository _repository;

  const GetClassroomStatsUseCase(this._repository);

  Future<Either<Failure, ClassroomStats>> call() =>
      _repository.getClassroomStats();
}

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

class GetEnrollmentStatsUseCase {
  final EnrollmentStatsRepository _repository;

  const GetEnrollmentStatsUseCase(this._repository);

  Future<Either<Failure, EnrollmentStats>> call({
    EnrollmentStatsWindow window = const EnrollmentStatsWindow.year(),
  }) {
    return _repository.getEnrollmentStats(window: window);
  }
}

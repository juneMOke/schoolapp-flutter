import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

class GetEnrollmentStatsUseCase {
  final EnrollmentStatsRepository _repository;

  const GetEnrollmentStatsUseCase(this._repository);

  Future<Either<Failure, EnrollmentStats>> call({
    EnrollmentStatsPeriod period = EnrollmentStatsPeriod.year,
    String? month,
    String? week,
  }) {
    return _repository.getEnrollmentStats(
      period: period,
      month: month,
      week: week,
    );
  }
}

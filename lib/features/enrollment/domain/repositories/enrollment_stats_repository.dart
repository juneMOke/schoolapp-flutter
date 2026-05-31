import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';

abstract class EnrollmentStatsRepository {
  Future<Either<Failure, EnrollmentStats>> getEnrollmentStats({
    EnrollmentStatsPeriod period = EnrollmentStatsPeriod.year,
    String? month,
    String? week,
  });
}

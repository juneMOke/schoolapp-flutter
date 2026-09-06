import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';

abstract class EnrollmentStatsRepository {
  Future<Either<Failure, EnrollmentStats>> getEnrollmentStats({
    EnrollmentStatsWindow window,
  });

  /// Les inscriptions nommées d'une journée, page par page.
  Future<Either<Failure, PaginatedResponse<DayEnrollmentEntry>>> getDayEntries({
    required DateTime day,
    required int page,
    required int size,
  });
}

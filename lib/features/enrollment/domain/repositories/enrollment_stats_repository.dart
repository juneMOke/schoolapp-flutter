import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';

abstract class EnrollmentStatsRepository {
  Future<Either<Failure, EnrollmentStats>> getEnrollmentStats({
    EnrollmentStatsWindow window,
  });

  /// Les inscriptions nommées de la fenêtre, page par page.
  ///
  /// Même fenêtre que l'agrégat, dérivée par le même code côté serveur : la
  /// liste ne peut pas compter autre chose que la carte posée au-dessus d'elle.
  Future<Either<Failure, PaginatedResponse<DayEnrollmentEntry>>> getEntries({
    required EnrollmentStatsWindow window,
    required int page,
    required int size,
    required EnrollmentEntriesOrder order,
  });
}

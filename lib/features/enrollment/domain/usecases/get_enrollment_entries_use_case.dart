import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

class GetEnrollmentEntriesUseCase {
  final EnrollmentStatsRepository _repository;

  const GetEnrollmentEntriesUseCase(this._repository);

  /// Taille de page de la spec.
  ///
  /// Le serveur plafonne à 100 et refuse au-delà, explicitement. Elle ne
  /// grandit pas avec la fenêtre : ce qui protège une liste de noms, dit le
  /// serveur, c'est la taille de page et non l'étroitesse de la fenêtre. Une
  /// année se lit en tournant les pages, ou s'emporte en PDF.
  static const int pageSize = 8;

  Future<Either<Failure, PaginatedResponse<DayEnrollmentEntry>>> call({
    required EnrollmentStatsWindow window,
    int page = 0,
  }) {
    return _repository.getEntries(
      window: window,
      page: page,
      size: pageSize,
      order: EnrollmentEntriesOrder.dashboard,
    );
  }
}

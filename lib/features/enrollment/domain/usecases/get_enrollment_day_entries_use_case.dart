import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

class GetEnrollmentDayEntriesUseCase {
  final EnrollmentStatsRepository _repository;

  const GetEnrollmentDayEntriesUseCase(this._repository);

  /// Taille de page de la spec.
  ///
  /// Le serveur plafonne à 100 et refuse au-delà, explicitement. Demander une
  /// grande page pour éviter de paginer se heurterait donc à un mur ; et
  /// paginer est de toute façon le bon geste sur une liste qui porte des noms.
  static const int pageSize = 8;

  Future<Either<Failure, PaginatedResponse<DayEnrollmentEntry>>> call({
    required DateTime day,
    int page = 0,
  }) {
    return _repository.getDayEntries(day: day, page: page, size: pageSize);
  }
}

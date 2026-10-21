import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_snapshot.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_dashboard_repository.dart';

class GetBoutiqueStatsUseCase {
  final BoutiqueDashboardRepository _repository;

  const GetBoutiqueStatsUseCase(this._repository);

  Future<Either<Failure, BoutiqueStatsSnapshot>> call({
    required String academicYearId,
    required DashboardWindow window,
  }) => _repository.stats(academicYearId: academicYearId, window: window);
}

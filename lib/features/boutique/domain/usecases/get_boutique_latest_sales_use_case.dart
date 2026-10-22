import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';

class GetBoutiqueLatestSalesUseCase {
  /// Les six derniers reçus : de quoi retrouver le ticket qu'un parent
  /// rapporte, sans devenir une liste complète des ventes.
  static const int defaultLimit = 6;

  final BoutiqueHistoryRepository _repository;

  const GetBoutiqueLatestSalesUseCase(this._repository);

  Future<Either<Failure, List<SaleHistoryEntry>>> call({
    required String academicYearId,
    required DashboardWindow window,
    int limit = defaultLimit,
  }) => _repository.latestSales(
    academicYearId: academicYearId,
    window: window,
    limit: limit,
  );
}

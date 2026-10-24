import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';

class GetBoutiqueProvisionalSalesUseCase {
  final BoutiqueHistoryRepository _repository;

  const GetBoutiqueProvisionalSalesUseCase(this._repository);

  Future<Either<Failure, ProvisionalSales>> call({
    required String academicYearId,
    required DashboardWindow window,
  }) => _repository.provisionalSales(
    academicYearId: academicYearId,
    window: window,
  );
}

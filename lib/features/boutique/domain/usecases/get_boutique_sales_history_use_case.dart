import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';

class GetBoutiqueSalesHistoryUseCase {
  final BoutiqueHistoryRepository _repository;

  const GetBoutiqueSalesHistoryUseCase(this._repository);

  Future<Either<Failure, List<SaleHistoryEntry>>> call({
    required String academicYearId,
    required SalesHistoryPeriod period,
  }) =>
      _repository.salesOfPeriod(academicYearId: academicYearId, period: period);
}

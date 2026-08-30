import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';

class GetBoutiqueSaleDetailUseCase {
  final BoutiqueHistoryRepository _repository;

  const GetBoutiqueSaleDetailUseCase(this._repository);

  Future<Either<Failure, SaleDetail>> call(String saleId) =>
      _repository.saleDetail(saleId);
}

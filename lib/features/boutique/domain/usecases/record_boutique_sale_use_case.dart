import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_sale_repository.dart';

/// Encaisse la vente au comptant : écriture locale, push différé.
class RecordBoutiqueSaleUseCase {
  final BoutiqueSaleRepository _repository;

  const RecordBoutiqueSaleUseCase(this._repository);

  Future<Either<Failure, RecordedSale>> call({
    required BoutiqueCart cart,
    required String academicYearId,
    String? cashierName,
  }) => _repository.recordSale(
    cart: cart,
    academicYearId: academicYearId,
    cashierName: cashierName,
  );
}

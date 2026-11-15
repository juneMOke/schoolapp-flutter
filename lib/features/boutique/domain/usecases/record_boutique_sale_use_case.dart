import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/cash_register_lock.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_sale_repository.dart';

/// Encaisse la vente au comptant : écriture locale, push différé.
///
/// Refusée, sans rien écrire, si la caisse d'une devise posée au comptoir est
/// close aujourd'hui (R11) : [CashRegisterClosedFailure].
class RecordBoutiqueSaleUseCase {
  final BoutiqueSaleRepository _repository;
  final CashRegisterLock? _lock;

  const RecordBoutiqueSaleUseCase(this._repository, {CashRegisterLock? lock})
    : _lock = lock;

  Future<Either<Failure, RecordedSale>> call({
    required BoutiqueCart cart,
    required String academicYearId,
    String? cashierName,
  }) async {
    final guard = await guardCashRegisters(_lock, tenderedCurrenciesOf(cart));
    return guard.fold(
      (failure) async => Left(failure),
      (_) => _repository.recordSale(
        cart: cart,
        academicYearId: academicYearId,
        cashierName: cashierName,
      ),
    );
  }
}

/// Les devises réellement posées au comptoir : celle du catalogue, ou celle
/// dans laquelle le client règle cette part du panier.
Set<String> tenderedCurrenciesOf(BoutiqueCart cart) => {
  for (final catalog in cart.currencies)
    if (cart.tenderFor(catalog).isConvertedFrom(catalog))
      cart.tenderFor(catalog).currency
    else
      catalog,
};

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Pose un taux de guichet dans la série de l'école.
///
/// Écriture locale : un taux se paramètre à la direction et vaut immédiatement
/// au guichet, sans attendre un aller-retour réseau. C'est ce qui rend la
/// bascule de devise utilisable là où il n'y a pas de réseau — c'est-à-dire là
/// où elle sert.
class SaveExchangeRateUseCase {
  final FinanceOfflineRepository _repository;

  const SaveExchangeRateUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String base,
    required String quote,
    required int rateMicros,
    required DateTime effectiveFrom,
    int? divergenceBandBp,
  }) => _repository.saveExchangeRate(
    base: base,
    quote: quote,
    rateMicros: rateMicros,
    effectiveFrom: effectiveFrom,
    divergenceBandBp: divergenceBandBp,
  );
}

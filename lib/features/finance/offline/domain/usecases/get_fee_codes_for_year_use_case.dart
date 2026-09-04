import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Natures de frais réellement facturées sur l'année, lues localement — ce que
/// le tableau de bord du Contrôle des frais offre à la sélection.
///
/// Des **codes**, jamais des libellés : l'écran est école-wide, et un même
/// `fee_code` porte des libellés différents d'un niveau à l'autre. Le rendu les
/// nomme par `localizedFeeLabel`.
class GetFeeCodesForYearUseCase {
  final FinanceOfflineRepository _repository;

  const GetFeeCodesForYearUseCase(this._repository);

  Future<Either<Failure, List<String>>> call({
    required String academicYearId,
  }) => _repository.getFeeCodesForYear(academicYearId);
}

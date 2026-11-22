import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Les natures de frais facturées sur l'année **avec leur(s) devise(s)**, lues
/// localement — ce que le choix des frais du Contrôle des frais groupe par
/// devise (spec Recouvrement v2, O1).
class GetFeeNaturesForYearUseCase {
  final FinanceOfflineRepository _repository;

  const GetFeeNaturesForYearUseCase(this._repository);

  Future<Either<Failure, List<({String feeCode, List<String> currencies})>>>
  call({required String academicYearId}) =>
      _repository.getFeeNaturesForYear(academicYearId);
}

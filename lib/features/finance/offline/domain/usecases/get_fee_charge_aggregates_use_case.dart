import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Position d'une liste d'élèves sur un frais donné (Contrôle des frais) :
/// attendu, payé composé et reste, lus localement.
class GetFeeChargeAggregatesUseCase {
  final FinanceOfflineRepository _repository;

  const GetFeeChargeAggregatesUseCase(this._repository);

  Future<Either<Failure, List<LocalFeeChargeAggregate>>> call({
    required String academicYearId,
    required String feeCode,
    required List<String> studentIds,
  }) => _repository.getFeeChargeAggregates(
    academicYearId: academicYearId,
    feeCode: feeCode,
    studentIds: studentIds,
  );
}

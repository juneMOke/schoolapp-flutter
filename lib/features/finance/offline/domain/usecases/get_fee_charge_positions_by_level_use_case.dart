import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Position de **toute la population** sur un frais, ventilée par niveau
/// (tableau de bord du Contrôle des frais), lue localement.
///
/// Se distingue de `GetFeeChargeAggregatesUseCase`, qui répond sur une liste
/// d'élèves connue : ici la population n'est pas fournie, elle est découverte
/// dans le grand-livre. [schoolLevelGroupId] borne au cycle ; `null` porte sur
/// toute l'école.
class GetFeeChargePositionsByLevelUseCase {
  final FinanceOfflineRepository _repository;

  const GetFeeChargePositionsByLevelUseCase(this._repository);

  Future<Either<Failure, List<LocalFeeLevelAggregate>>> call({
    required String academicYearId,
    required String feeCode,
    String? schoolLevelGroupId,
  }) => _repository.getFeeChargePositionsByLevel(
    academicYearId: academicYearId,
    feeCode: feeCode,
    schoolLevelGroupId: schoolLevelGroupId,
  );
}

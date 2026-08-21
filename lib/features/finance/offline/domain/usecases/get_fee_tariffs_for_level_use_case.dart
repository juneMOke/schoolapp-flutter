import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Grille tarifaire locale applicable à un niveau sur une année — ce que le
/// Contrôle des frais propose de contrôler.
class GetFeeTariffsForLevelUseCase {
  final FinanceOfflineRepository _repository;

  const GetFeeTariffsForLevelUseCase(this._repository);

  Future<Either<Failure, List<LocalFeeTariff>>> call({
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  }) => _repository.getFeeTariffsForLevel(
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
  );
}

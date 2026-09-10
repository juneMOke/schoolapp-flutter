import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Position de **toute la population** sur une sélection de frais, ventilée par
/// niveau — la lecture unique du tableau de bord du Recouvrement.
///
/// Se distingue de `GetFeeChargePositionsByLevelUseCase`, borné à une seule
/// nature : celui-ci garde le détail **par frais**, dont le taux poste par poste
/// a besoin. Il porte donc l'écran entier — les quatre chiffres clés, le taux
/// par frais, le classement et la simulation en dérivent tous en mémoire, sans
/// une seconde lecture.
///
/// [schoolLevelGroupId] borne au cycle ; `null` porte sur toute l'école.
class GetRecoveryPositionsUseCase {
  final FinanceOfflineRepository _repository;

  const GetRecoveryPositionsUseCase(this._repository);

  Future<Either<Failure, List<LocalRecoveryLine>>> call({
    required String academicYearId,
    required List<String> feeCodes,
    String? schoolLevelGroupId,
  }) => _repository.getRecoveryPositions(
    academicYearId: academicYearId,
    feeCodes: feeCodes,
    schoolLevelGroupId: schoolLevelGroupId,
  );
}

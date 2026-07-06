import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Traitement offline d'un cas (DF-2, régime C, LWW). Renvoie toujours la
/// sanction courante (garde-fou anti-effacement DG-3).
class UpdateDisciplinaryCaseOfflineUseCase {
  final DisciplinaryCaseOfflineRepository _repository;

  const UpdateDisciplinaryCaseOfflineUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String caseId,
    required DisciplinaryStatus status,
    DisciplinarySanction? sanction,
    int? expectedVersion,
  }) => _repository.updateCase(
    caseId: caseId,
    status: status,
    sanction: sanction,
    expectedVersion: expectedVersion,
  );
}

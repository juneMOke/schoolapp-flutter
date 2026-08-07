import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/disciplinary_case_repository.dart';

/// Traitement d'un cas disciplinaire (DF-2) : status + sanction courante.
/// Renvoie toujours la sanction courante (garde-fou anti-effacement DG-3).
class UpdateDisciplinaryCaseStatusUseCase {
  final DisciplinaryCaseRepository _repository;

  const UpdateDisciplinaryCaseStatusUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String caseId,
    required DisciplinaryStatus status,
    DisciplinarySanction? sanction,
    int? expectedVersion,
  }) => _repository.updateDisciplinaryCaseStatus(
    caseId: caseId,
    status: status,
    sanction: sanction,
    expectedVersion: expectedVersion,
  );
}

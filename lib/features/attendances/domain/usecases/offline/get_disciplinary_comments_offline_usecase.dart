import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_comment.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Lecture locale des commentaires d'un cas (DF-B). `content` SENSIBLE chargé
/// ici seulement (au détail), pas dans la liste.
class GetDisciplinaryCommentsOfflineUseCase {
  final DisciplinaryCaseOfflineRepository _repository;

  const GetDisciplinaryCommentsOfflineUseCase(this._repository);

  Future<Either<Failure, List<DisciplinaryComment>>> call({
    required String caseId,
  }) => _repository.getCommentsForCase(caseId: caseId);
}

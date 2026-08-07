import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Nombre de commentaires par cas (badge de liste, sans charger `content`).
class GetDisciplinaryCommentCountsOfflineUseCase {
  final DisciplinaryCaseOfflineRepository _repository;

  const GetDisciplinaryCommentCountsOfflineUseCase(this._repository);

  Future<Either<Failure, Map<String, int>>> call({
    required List<String> caseIds,
  }) => _repository.commentCounts(caseIds: caseIds);
}

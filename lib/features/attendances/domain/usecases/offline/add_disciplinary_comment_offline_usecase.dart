import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_comment.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Ajout offline d'un commentaire (DF-B, append-only). Bumpe `case.updated_at`
/// pour rester re-pullable (DF-F).
class AddDisciplinaryCommentOfflineUseCase {
  final DisciplinaryCaseOfflineRepository _repository;

  const AddDisciplinaryCommentOfflineUseCase(this._repository);

  Future<Either<Failure, DisciplinaryComment>> call({
    required String caseId,
    required String content,
    String? authorName,
  }) => _repository.addComment(
    caseId: caseId,
    content: content,
    authorName: authorName,
  );
}
